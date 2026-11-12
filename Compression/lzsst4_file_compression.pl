#!/usr/bin/perl

# Author: Trizen
# Refactored: November 2026 (v0.08 - Fixed LZ77 Matching, Constant Usage & Symbol Pipeline)

use 5.036;

use Getopt::Std    qw(getopts);
use File::Basename qw(basename);
use List::Util     qw(max sum);

use constant {
    PKGNAME    => 'LZSST3',
    VERSION    => '0.08',
    FORMAT     => 'lzs3',
    CHUNK_SIZE => 1 << 19,    # 512 KB chunks
    SIGNATURE  => "LZS3\x01",
};

# Stateful LSB-First BitWriter
package BitWriter {
    sub new ($class, $fh) {
        bless { fh => $fh, buf => 0, cnt => 0 }, $class;
    }
    sub write ($self, $val, $n) {
        return if $n == 0;
        $self->{buf} |= (($val & ((1 << $n) - 1)) << $self->{cnt});
        $self->{cnt} += $n;
        while ($self->{cnt} >= 8) {
            print {$self->{fh}} chr($self->{buf} & 0xFF);
            $self->{buf} >>= 8;
            $self->{cnt} -= 8;
        }
    }
    sub write_bitstring ($self, $bitstr) {
        foreach my $bit (split('', $bitstr)) {
            $self->write($bit + 0, 1);
        }
    }
    sub flush ($self) {
        if ($self->{cnt} > 0) {
            print {$self->{fh}} chr($self->{buf} & 0xFF);
            $self->{buf} = 0;
            $self->{cnt} = 0;
        }
    }
}

# Stateful LSB-First BitReader
package BitReader {
    sub new ($class, $data_ref) {
        bless { data => $data_ref, pos => 0, buf => 0, cnt => 0 }, $class;
    }
    sub read ($self, $n) {
        return 0 if $n == 0;
        while ($self->{cnt} < $n) {
            if ($self->{pos} >= length(${ $self->{data} })) {
                return undef;
            }
            my $byte = ord(substr(${ $self->{data} }, $self->{pos}++, 1));
            $self->{buf} |= ($byte << $self->{cnt});
            $self->{cnt} += 8;
        }
        my $val = $self->{buf} & ((1 << $n) - 1);
        $self->{buf} >>= $n;
        $self->{cnt} -= $n;
        return $val;
    }
    sub read_bitstring ($self, $n) {
        my $res = '';
        for (1 .. $n) {
            my $bit = $self->read(1);
            return undef if !defined $bit;
            $res .= $bit;
        }
        return $res;
    }
}

package main;

sub usage ($code) {
    print <<"EOH";
usage: $0 [options] [input file] [output file]

options:
        -e            : extract
        -i <filename> : input filename
        -o <filename> : output filename
        -r            : rewrite output
        -v            : version number
        -h            : this message

examples:
         $0 document.txt
         $0 document.txt archive.${\FORMAT}
         $0 archive.${\FORMAT} document.txt
         $0 -e -i archive.${\FORMAT} -o document.txt
EOH
    exit($code // 0);
}

sub version {
    printf("%s v%s\n", PKGNAME, VERSION);
    exit;
}

sub valid_archive ($fh) {
    if (read($fh, (my $sig), length(SIGNATURE), 0) == length(SIGNATURE)) {
        return $sig eq SIGNATURE;
    }
    return 0;
}

sub main {
    my %opt;
    getopts('ei:o:vhr', \%opt);

    $opt{h} && usage(0);
    $opt{v} && version();

    my ($input, $output) = @ARGV;
    $input  //= $opt{i} // usage(2);
    $output //= $opt{o};

    my $ext = qr{\.${\FORMAT}\z}io;
    if ($opt{e} || $input =~ $ext) {
        if (not defined $output) {
            ($output = basename($input)) =~ s{$ext}{}
              || die "$0: no output file specified!\n";
        }

        if (not $opt{r} and -e $output) {
            print "'$output' already exists! -- Replace? [y/N] ";
            <STDIN> =~ /^y/i || exit 17;
        }

        decompress_file($input, $output)
          || die "$0: error: decompression failed!\n";
    }
    elsif ($input !~ $ext || (defined($output) && $output =~ $ext)) {
        $output //= basename($input) . '.' . FORMAT;
        compress_file($input, $output)
          || die "$0: error: compression failed!\n";
    }
    else {
        warn "$0: don't know what to do...\n";
        usage(1);
    }
}

sub make_deflate_symbols ($size) {
    my @DISTANCE_SYMBOLS = map { [$_, 0] } (0 .. 4);

    until ($DISTANCE_SYMBOLS[-1][0] > $size) {
        push @DISTANCE_SYMBOLS, [int($DISTANCE_SYMBOLS[-1][0] * (4 / 3)), $DISTANCE_SYMBOLS[-1][1] + 1];
        push @DISTANCE_SYMBOLS, [int($DISTANCE_SYMBOLS[-1][0] * (3 / 2)), $DISTANCE_SYMBOLS[-1][1]];
    }

    my @LENGTH_SYMBOLS = map { [$_, 0] } (4 .. 10);
    {
        my $delta = 1;
        until ($LENGTH_SYMBOLS[-1][0] > 163) {
            push @LENGTH_SYMBOLS, [$LENGTH_SYMBOLS[-1][0] + $delta, $LENGTH_SYMBOLS[-1][1] + 1];
            $delta *= 2;
            push @LENGTH_SYMBOLS, [$LENGTH_SYMBOLS[-1][0] + $delta, $LENGTH_SYMBOLS[-1][1]];
            push @LENGTH_SYMBOLS, [$LENGTH_SYMBOLS[-1][0] + $delta, $LENGTH_SYMBOLS[-1][1]];
            push @LENGTH_SYMBOLS, [$LENGTH_SYMBOLS[-1][0] + $delta, $LENGTH_SYMBOLS[-1][1]];
        }
        push @LENGTH_SYMBOLS, [258, 0];
    }

    my @LENGTH_INDICES;
    foreach my $i (0 .. $#LENGTH_SYMBOLS) {
        my ($min, $bits) = @{$LENGTH_SYMBOLS[$i]};
        foreach my $k ($min .. $min + (1 << $bits) - 1) {
            $LENGTH_INDICES[$k] = $i;
        }
    }

    return (\@DISTANCE_SYMBOLS, \@LENGTH_INDICES, \@LENGTH_SYMBOLS);
}

sub find_distance_index ($dist, $distance_symbols) {
    my ($lo, $hi) = (0, $#{$distance_symbols});
    while ($lo < $hi) {
        my $mid = ($lo + $hi + 1) >> 1;
        if ($distance_symbols->[$mid][0] <= $dist) {
            $lo = $mid;
        }
        else {
            $hi = $mid - 1;
        }
    }
    return $lo;
}

sub find_match ($str, $la, $min_len, $max_len, $end, $head_ref, $prev_ref, $max_chain, $hash_mask) {
    my $best_n = $min_len - 1;
    my $best_p = $la;
    my $chain_len = 0;

    return (1, $la) if $la + 2 > $end;

    my $b0 = ord(substr($str, $la,     1));
    my $b1 = ord(substr($str, $la + 1, 1));
    my $b2 = ord(substr($str, $la + 2, 1));
    my $h  = (($b0 << 10) ^ ($b1 << 5) ^ $b2) & $hash_mask;

    my $p = $head_ref->[$h];
    my $limit = $la > 32768 ? $la - 32768 : 0;

    while ($p >= $limit && $chain_len++ < $max_chain) {
        if (ord(substr($str, $p + $best_n, 1)) == ord(substr($str, $la + $best_n, 1))) {
            my $n = 0;
            while ($la + $n <= $end && $p + $n <= $end && ord(substr($str, $la + $n, 1)) == ord(substr($str, $p + $n, 1))) {
                ++$n;
                last if $n >= $max_len;
            }
            if ($n > $best_n) {
                $best_n = $n;
                $best_p = $p;
                last if $best_n >= $max_len;
            }
        }
        $p = $prev_ref->[$p & (CHUNK_SIZE - 1)];
    }

    return ($best_n >= $min_len ? $best_n : 1, $best_p);
}

sub lz77_compression ($str) {
    my $la        = 0;
    my $str_len   = length($str);
    my $end       = $str_len - 1;

    my $min_len       = 4;
    my $max_len       = 258;
    my $max_chain_len = 64;

    my $HASH_BITS = 16;
    my $HASH_SIZE = 1 << $HASH_BITS;
    my $HASH_MASK = $HASH_SIZE - 1;

    my @head = (-1) x $HASH_SIZE;
    my @prev = (0) x CHUNK_SIZE;

    my (@literals, @distances, @lengths);

    while ($la <= $end) {
        my ($n1, $p1) = find_match($str, $la, $min_len, $max_len, $end, \@head, \@prev, $max_chain_len, $HASH_MASK);
        my ($n2, $p2) = ($la + 1 <= $end) ? find_match($str, $la + 1, $min_len, $max_len, $end, \@head, \@prev, $max_chain_len, $HASH_MASK) : (1, $la + 1);

        my $best_n = $n1;
        my $best_p = $p1;

        if ($n2 > $n1 && $p1 < $p2) {
            push @lengths,   0;
            push @distances, 0;
            push @literals,  ord(substr($str, $la, 1));

            if ($la + 2 <= $end) {
                my $b0 = ord(substr($str, $la,     1));
                my $b1 = ord(substr($str, $la + 1, 1));
                my $b2 = ord(substr($str, $la + 2, 1));
                my $h  = (($b0 << 10) ^ ($b1 << 5) ^ $b2) & $HASH_MASK;
                $prev[$la & (CHUNK_SIZE - 1)] = $head[$h];
                $head[$h] = $la;
            }

            $la += 1;
            $best_n = $n2;
            $best_p = $p2;
        }

        my $matched_len = ($la + $best_n <= $str_len) ? $best_n : ($str_len - $la);

        for (my $i = 0 ; $i < $matched_len ; ++$i) {
            my $curr = $la + $i;
            if ($curr + 2 <= $end) {
                my $b0 = ord(substr($str, $curr,     1));
                my $b1 = ord(substr($str, $curr + 1, 1));
                my $b2 = ord(substr($str, $curr + 2, 1));
                my $h  = (($b0 << 10) ^ ($b1 << 5) ^ $b2) & $HASH_MASK;
                $prev[$curr & (CHUNK_SIZE - 1)] = $head[$h];
                $head[$h] = $curr;
            }
        }

        if ($best_n >= $min_len) {
            push @lengths,   $best_n;
            push @distances, $la - $best_p;
            push @literals,  undef;
            $la += $best_n;
        }
        else {
            push @lengths,   (0) x $best_n;
            push @distances, (0) x $best_n;
            push @literals,  map { ord($_) } split('', substr($str, $la, $best_n));
            $la += $best_n;
        }
    }

    return (\@literals, \@distances, \@lengths);
}

sub lz77_decompression ($literals, $distances, $lengths) {
    my $data     = '';
    my $data_len = 0;

    foreach my $i (0 .. $#$lengths) {
        if ($lengths->[$i] == 0) {
            $data .= chr($literals->[$i]);
            ++$data_len;
            next;
        }

        my $length = $lengths->[$i];
        my $dist   = $distances->[$i];

        if ($dist >= $length) {
            $data .= substr($data, $data_len - $dist, $length);
        }
        elsif ($dist == 1) {
            $data .= substr($data, -1) x $length;
        }
        else {
            my $pattern   = substr($data, $data_len - $dist, $dist);
            my $full_reps = int(($length + $dist - 1) / $dist) + 1;
            $data .= substr($pattern x $full_reps, 0, $length);
        }

        $data_len += $length;
    }

    return $data;
}

sub delta_encode ($integers) {
    my @deltas;
    my $prev = 0;
    unshift(@$integers, scalar(@$integers));

    while (@$integers) {
        my $curr = shift(@$integers);
        push @deltas, $curr - $prev;
        $prev = $curr;
    }

    my $bitstring = '';
    foreach my $d (@deltas) {
        if ($d == 0) {
            $bitstring .= '0';
        }
        else {
            my $t = sprintf('%b', abs($d));
            $bitstring .= '1' . (($d < 0) ? '0' : '1') . ('1' x (length($t) - 1)) . '0' . substr($t, 1);
        }
    }
    return $bitstring;
}

sub delta_decode ($br) {
    my @deltas;
    my $len = 0;
    my $k = 0;

    while (1) {
        my $bit = $br->read(1);
        return [] if !defined $bit;

        if ($bit == 0) {
            push @deltas, 0;
        }
        else {
            my $sign_bit = $br->read(1);
            my $n = 0;
            while (1) {
                my $b = $br->read(1);
                last if !defined $b;
                if ($b == 1) {
                    ++$n;
                }
                else {
                    last;
                }
            }
            my $val = 1;
            for (1 .. $n) {
                $val = ($val << 1) | $br->read(1);
            }
            push @deltas, ($sign_bit == 1 ? $val : -$val);
        }

        if ($k == 0) {
            $len = pop(@deltas);
            last if !defined $len;
        }
        last if $k >= $len;
        ++$k;
    }

    my @acc;
    my $prev = $len;
    foreach my $d (@deltas) {
        $prev += $d;
        push @acc, $prev;
    }

    return \@acc;
}

sub walk ($node, $code, $h, $rev_h) {
    my $c = $node->[0] // return ($h, $rev_h);
    if (ref $c) {
        walk($c->[$_], $code . $_, $h, $rev_h) for ('0', '1');
    }
    else {
        $h->{$c} = $code;
        $rev_h->{$code} = $c;
    }
    return ($h, $rev_h);
}

sub _heap_push ($heap, $item) {
    push @$heap, $item;
    my $i = $#$heap;
    while ($i > 0) {
        my $p = ($i - 1) >> 1;
        last if $heap->[$p][1] <= $heap->[$i][1];
        @{$heap}[$p, $i] = @{$heap}[$i, $p];
        $i = $p;
    }
}

sub _heap_pop ($heap) {
    return pop @$heap if @$heap == 1;
    my $min = $heap->[0];
    $heap->[0] = pop @$heap;
    my ($i, $n) = (0, scalar @$heap);
    while (1) {
        my ($l, $r, $s) = ($i * 2 + 1, $i * 2 + 2, $i);
        $s = $l if $l < $n && $heap->[$l][1] < $heap->[$s][1];
        $s = $r if $r < $n && $heap->[$r][1] < $heap->[$s][1];
        last if $s == $i;
        @{$heap}[$i, $s] = @{$heap}[$s, $i];
        $i = $s;
    }
    return $min;
}

sub mktree_from_freq ($freq) {
    my @heap;
    _heap_push(\@heap, [$_, $freq->{$_}]) for sort { $a <=> $b } keys %$freq;

    while (@heap > 1) {
        my $x = _heap_pop(\@heap);
        my $y = _heap_pop(\@heap);
        _heap_push(\@heap, [[$x, $y], $x->[1] + $y->[1]]);
    }

    return walk($heap[0], '', {}, {});
}

sub encode_huffman_table ($bytes) {
    my %freq;
    ++$freq{$_} for @$bytes;

    my ($h, $rev_h) = mktree_from_freq(\%freq);
    my $enc = join('', @{$h}{@$bytes});

    my $max_symbol = max(keys %freq) // 0;
    my @freqs;
    push @freqs, $freq{$_} // 0 for 0 .. $max_symbol;

    my $delta_bits = delta_encode(\@freqs);
    return ($delta_bits, $enc);
}

sub decode_huffman_table_from_br ($br) {
    my @freqs = @{delta_decode($br)};
    my %freq;
    my $num_symbols = 0;

    foreach my $i (0 .. $#freqs) {
        if ($freqs[$i]) {
            $freq{$i} = $freqs[$i];
            $num_symbols += $freqs[$i];
        }
    }

    return [] if $num_symbols == 0;

    my (undef, $rev_dict) = mktree_from_freq(\%freq);

    my $enc_len = $br->read(32);
    return [] if !defined $enc_len;

    my @symbols;
    for (1 .. $num_symbols) {
        my $code = '';
        while (1) {
            my $bit = $br->read(1);
            die "Unexpected EOF during Huffman decoding\n" if !defined $bit;
            $code .= $bit;
            if (exists $rev_dict->{$code}) {
                push @symbols, $rev_dict->{$code};
                last;
            }
        }
    }

    return \@symbols;
}

sub generate_symbols_list ($literals, $distances, $lengths, $len_syms_ref, $dist_syms_ref, $LENGTH_INDICES, $DISTANCE_SYMBOLS, $LENGTH_SYMBOLS, $bw) {
    my @offsets;
    foreach my $k (0 .. $#{$literals}) {
        if ($lengths->[$k] == 0) {
            push @$len_syms_ref, $literals->[$k];
            next;
        }

        my $len  = $lengths->[$k];
        my $dist = $distances->[$k];

        {
            my $len_idx = $LENGTH_INDICES->[$len];
            my ($min, $bits) = @{$LENGTH_SYMBOLS->[$len_idx]};
            push @$len_syms_ref, $len_idx + 256;
            push @offsets, [$len - $min, $bits] if $bits > 0;
        }

        {
            my $dist_idx = find_distance_index($dist, $DISTANCE_SYMBOLS);
            my ($min, $bits) = @{$DISTANCE_SYMBOLS->[$dist_idx]};
            push @$dist_syms_ref, $dist_idx;
            push @offsets, [$dist - $min, $bits] if $bits > 0;
        }
    }

    my ($len_delta_bits, $len_huff_bits)   = encode_huffman_table($len_syms_ref);
    my ($dist_delta_bits, $dist_huff_bits) = encode_huffman_table($dist_syms_ref);

    $bw->write_bitstring($len_delta_bits);
    $bw->write(length($len_huff_bits), 32);
    $bw->write_bitstring($len_huff_bits);

    $bw->write_bitstring($dist_delta_bits);
    $bw->write(length($dist_huff_bits), 32);
    $bw->write_bitstring($dist_huff_bits);

    foreach my $off (@offsets) {
        $bw->write($off->[0], $off->[1]);
    }

    $bw->flush();
}

sub deflate_encode ($size, $literals, $distances, $lengths, $out_fh) {
    my ($DISTANCE_SYMBOLS, $LENGTH_INDICES, $LENGTH_SYMBOLS) = make_deflate_symbols($size);

    my (@len_symbols, @dist_symbols);
    my $chunk_buf = '';
    open my $chunk_fh, '>', \$chunk_buf;
    my $bw = BitWriter->new($chunk_fh);

    generate_symbols_list($literals, $distances, $lengths, \@len_symbols, \@dist_symbols, $LENGTH_INDICES, $DISTANCE_SYMBOLS, $LENGTH_SYMBOLS, $bw);
    close $chunk_fh;

    my $total_chunk_data = pack('N', $size) . pack('N', length($chunk_buf)) . $chunk_buf;
    print $out_fh $total_chunk_data;
}

sub deflate_decode ($fh) {
    my $size_raw = '';
    read($fh, $size_raw, 4) == 4 or return undef;
    my $size = unpack('N', $size_raw);

    my $chunk_len_raw = '';
    read($fh, $chunk_len_raw, 4) == 4 or return undef;
    my $chunk_len = unpack('N', $chunk_len_raw);

    my $chunk_payload = '';
    read($fh, $chunk_payload, $chunk_len) == $chunk_len or return undef;

    my ($DISTANCE_SYMBOLS, $LENGTH_INDICES, $LENGTH_SYMBOLS) = make_deflate_symbols($size);

    my $br = BitReader->new(\$chunk_payload);
    my $len_symbols  = decode_huffman_table_from_br($br);
    my $dist_symbols = decode_huffman_table_from_br($br);

    my (@literals, @lengths, @distances);
    my $j = 0;

    foreach my $i (@$len_symbols) {
        if ($i >= 256) {
            my $dist = $dist_symbols->[$j++];
            my $l_sym = $LENGTH_SYMBOLS->[$i - 256];
            my $d_sym = $DISTANCE_SYMBOLS->[$dist];

            my $l_val = $l_sym->[0] + ($l_sym->[1] > 0 ? $br->read($l_sym->[1]) : 0);
            my $d_val = $d_sym->[0] + ($d_sym->[1] > 0 ? $br->read($d_sym->[1]) : 0);

            push @literals,  undef;
            push @lengths,   $l_val;
            push @distances, $d_val;
        }
        else {
            push @literals,  $i;
            push @lengths,   0;
            push @distances, 0;
        }
    }

    return (\@literals, \@distances, \@lengths);
}

sub compress_file ($input, $output) {
    open my $fh, '<:raw', $input
      or die "Can't open file <<$input>> for reading: $!";

    open my $out_fh, '>:raw', $output
      or die "Can't open file <<$output>> for write: $!";

    print $out_fh SIGNATURE;

    while (read($fh, (my $chunk), CHUNK_SIZE)) {
        my ($literals, $distances, $lengths) = lz77_compression($chunk);
        deflate_encode(length($chunk), $literals, $distances, $lengths, $out_fh);
    }

    close $fh;
    close $out_fh;
}

sub decompress_file ($input, $output) {
    open my $fh, '<:raw', $input
      or die "Can't open file <<$input>> for reading: $!";

    valid_archive($fh) || die "$0: file `$input' is not a valid archive!\n";

    open my $out_fh, '>:raw', $output
      or die "Can't open file <<$output>> for writing: $!";

    while (!eof($fh)) {
        my ($literals, $distances, $lengths) = deflate_decode($fh);
        last if !defined $literals;
        print $out_fh lz77_decompression($literals, $distances, $lengths);
    }

    close $fh;
    close $out_fh;
}

main();
exit(0);