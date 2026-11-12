#!/usr/bin/perl

# Author: Trizen
# Date: 17 June 2023
# Refactored: November 2026
# https://github.com/trizen

# Compress/decompress files using LZ77 compression (LZSS variant with hash tables and lazy matching) + Huffman coding.

# Encoding the literals and the pointers using a DEFLATE-like approach.
# This version is memory-friendly, supporting arbitrary large chunk sizes.

# References:
#   Data Compression (Summer 2023) - Lecture 11 - DEFLATE (gzip)
#   https://youtube.com/watch?v=SJPvNi4HrWQ
#
#   DEFLATE Compressed Data Format Specification version 1.3
#   https://datatracker.ietf.org/doc/html/rfc1951

use 5.036;

use Getopt::Std    qw(getopts);
use File::Basename qw(basename);
use List::Util     qw(max);

use constant {
    PKGNAME => 'LZSST2',
    VERSION => '0.02',
    FORMAT  => 'lzsst2',

    CHUNK_SIZE => 1 << 19,    # 512 KB per chunk
};

use constant SIGNATURE => uc(FORMAT) . chr(1);

sub usage {
    my ($code) = @_;
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
    printf("%s %s\n", PKGNAME, VERSION);
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

sub find_match ($symbols, $la, $min_len, $max_len, $end, $head_ref, $prev_ref, $max_chain, $hash_mask) {
    my $best_n    = $min_len - 1;
    my $best_p    = $la;
    my $chain_len = 0;

    return (1, $la) if $la + 2 > $end;

    my $b0 = $symbols->[$la];
    my $b1 = $symbols->[$la + 1];
    my $b2 = $symbols->[$la + 2];
    my $h  = (($b0 << 10) ^ ($b1 << 5) ^ $b2) & $hash_mask;

    my $p     = $head_ref->[$h];
    my $limit = $la > CHUNK_SIZE ? $la - CHUNK_SIZE : 0;

    while ($p >= $limit && $chain_len++ < $max_chain) {
        if ($la + $best_n <= $end and $symbols->[$p + $best_n] == $symbols->[$la + $best_n]) {
            my $n = 0;
            while ($la + $n <= $end && $p + $n <= $end && $symbols->[$la + $n] == $symbols->[$p + $n]) {
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

sub lz77_compression ($str, %params) {
    my $la      = 0;
    my $str_len = length($str);
    my $end     = $str_len - 1;
    my @symbols = unpack('C*', $str);

    my $min_len         = $params{min_len}         // 4;
    my $max_len         = $params{max_len}         // 258;
    my $max_chain_len   = $params{max_chain_len}   // 64;
    my $max_chain_width = $params{max_chain_width} // 32;

    my $HASH_BITS = 16;
    my $HASH_SIZE = 1 << $HASH_BITS;
    my $HASH_MASK = $HASH_SIZE - 1;

    my @head = (-1) x $HASH_SIZE;
    my @prev = (0) x CHUNK_SIZE;

    my (@literals, @distances, @lengths);

    while ($la <= $end) {
        my ($n1, $p1) = find_match(\@symbols, $la, $min_len, $max_len, $end, \@head, \@prev, $max_chain_len, $HASH_MASK);

        my $best_n = $n1;
        my $best_p = $p1;

        my $matched_len = ($la + $best_n <= $str_len) ? $best_n : ($str_len - $la);

        # Smart Chain Population
        if ($best_n >= $min_len) {
            my $insert_limit = ($best_n - $min_len < $best_n - 2) ? ($best_n - $min_len) : ($best_n - 2);
            $insert_limit = $max_chain_width if $insert_limit > $max_chain_width;

            for (my $i = 0 ; $i <= $insert_limit ; ++$i) {
                my $curr = $la + $i;
                if ($curr + 2 <= $end) {
                    my $b0 = $symbols[$curr];
                    my $b1 = $symbols[$curr + 1];
                    my $b2 = $symbols[$curr + 2];
                    my $h  = (($b0 << 10) ^ ($b1 << 5) ^ $b2) & $HASH_MASK;
                    $prev[$curr & (CHUNK_SIZE - 1)] = $head[$h];
                    $head[$h] = $curr;
                }
            }
        }
        else {
            # Standard single-step update for non-matches
            my $curr = $la;
            if ($curr + 2 <= $end) {
                my $b0 = $symbols[$curr];
                my $b1 = $symbols[$curr + 1];
                my $b2 = $symbols[$curr + 2];
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
            push @literals, $symbols[$la];
            $la += 1;
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

sub read_bit ($fh, $bitstring) {
    if (($$bitstring // '') eq '') {
        $$bitstring = unpack('b*', getc($fh) // return undef);
    }
    return chop($$bitstring);
}

sub read_bits ($fh, $bits_len) {
    my $data = '';
    read($fh, $data, $bits_len >> 3);
    $data = unpack('B*', $data);

    while (length($data) < $bits_len) {
        $data .= unpack('B*', getc($fh) // return undef);
    }

    if (length($data) > $bits_len) {
        $data = substr($data, 0, $bits_len);
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

    return pack('B*', $bitstring);
}

sub delta_decode ($fh) {
    my @deltas;
    my $buffer = '';
    my $len    = 0;

    for (my $k = 0 ; $k <= $len ; ++$k) {
        my $bit = read_bit($fh, \$buffer);

        if ($bit eq '0') {
            push @deltas, 0;
        }
        else {
            my $sign_bit = read_bit($fh, \$buffer);
            my $n        = 0;
            ++$n while (read_bit($fh, \$buffer) eq '1');
            my $d = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. $n));
            push @deltas, ($sign_bit eq '1' ? $d : -$d);
        }

        if ($k == 0) {
            $len = pop(@deltas);
        }
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
        $h->{$c}        = $code;
        $rev_h->{$code} = $c;
    }
    return ($h, $rev_h);
}

# Min-heap functions
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

sub huffman_encode ($bytes, $dict) {
    return join('', @{$dict}{@$bytes});
}

sub huffman_decode ($bits, $hash) {
    local $" = '|';
    return [split(' ', $bits =~ s/(@{[sort { length($a) <=> length($b) } keys %{$hash}]})/$hash->{$1} /gr)];
}

sub create_huffman_entry ($bytes, $out_fh) {
    my %freq;
    ++$freq{$_} for @$bytes;

    my ($h, $rev_h) = mktree_from_freq(\%freq);
    my $enc = huffman_encode($bytes, $h);

    my $max_symbol = max(keys %freq) // 0;

    my @freqs;
    foreach my $i (0 .. $max_symbol) {
        push @freqs, $freq{$i} // 0;
    }

    print $out_fh delta_encode(\@freqs);
    print $out_fh pack("N",  length($enc));
    print $out_fh pack("B*", $enc);
}

sub decode_huffman_entry ($fh) {
    my @freqs = @{delta_decode($fh)};

    my %freq;
    foreach my $i (0 .. $#freqs) {
        if ($freqs[$i]) {
            $freq{$i} = $freqs[$i];
        }
    }

    my (undef, $rev_dict) = mktree_from_freq(\%freq);
    my $enc_len = unpack('N', join('', map { getc($fh) // die "error" } 1 .. 4));

    if ($enc_len > 0) {
        return huffman_decode(read_bits($fh, $enc_len), $rev_dict);
    }

    return [];
}

sub deflate_encode ($size, $literals, $distances, $lengths, $out_fh) {
    my ($DISTANCE_SYMBOLS, $LENGTH_INDICES, $LENGTH_SYMBOLS) = make_deflate_symbols($size);

    my @len_symbols;
    my @dist_symbols;
    my $offset_bits = '';

    foreach my $k (0 .. $#{$literals}) {
        if ($lengths->[$k] == 0) {
            push @len_symbols, $literals->[$k];
            next;
        }

        my $len  = $lengths->[$k];
        my $dist = $distances->[$k];

        {
            my $len_idx = $LENGTH_INDICES->[$len];
            my ($min, $bits) = @{$LENGTH_SYMBOLS->[$len_idx]};

            push @len_symbols, $len_idx + 256;

            if ($bits > 0) {
                $offset_bits .= sprintf('%0*b', $bits, $len - $min);
            }
        }

        {
            my $dist_idx = find_distance_index($dist, $DISTANCE_SYMBOLS);
            my ($min, $bits) = @{$DISTANCE_SYMBOLS->[$dist_idx]};

            push @dist_symbols, $dist_idx;

            if ($bits > 0) {
                $offset_bits .= sprintf('%0*b', $bits, $dist - $min);
            }
        }
    }

    print $out_fh pack('N', $size);
    create_huffman_entry(\@len_symbols,  $out_fh);
    create_huffman_entry(\@dist_symbols, $out_fh);
    print $out_fh pack('B*', $offset_bits);
}

sub deflate_decode ($fh) {
    my $size = unpack('N', join('', map { getc($fh) // return undef } 1 .. 4));
    my ($DISTANCE_SYMBOLS, $LENGTH_INDICES, $LENGTH_SYMBOLS) = make_deflate_symbols($size);

    my $len_symbols  = decode_huffman_entry($fh);
    my $dist_symbols = decode_huffman_entry($fh);

    my $bits_len = 0;

    foreach my $i (@$dist_symbols) {
        $bits_len += $DISTANCE_SYMBOLS->[$i][1];
    }

    foreach my $i (@$len_symbols) {
        if ($i >= 256) {
            $bits_len += $LENGTH_SYMBOLS->[$i - 256][1];
        }
    }

    my $bits = read_bits($fh, $bits_len);

    my @literals;
    my @lengths;
    my @distances;

    my $j = 0;

    foreach my $i (@$len_symbols) {
        if ($i >= 256) {
            my $dist = $dist_symbols->[$j++];
            push @literals,  undef;
            push @lengths,   $LENGTH_SYMBOLS->[$i - 256][0] + oct('0b' . substr($bits, 0, $LENGTH_SYMBOLS->[$i - 256][1], ''));
            push @distances, $DISTANCE_SYMBOLS->[$dist][0] + oct('0b' . substr($bits, 0, $DISTANCE_SYMBOLS->[$dist][1], ''));
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

    valid_archive($fh) || die "$0: file `$input' is not a \U${\FORMAT}\E archive!\n";

    open my $out_fh, '>:raw', $output
      or die "Can't open file <<$output>> for writing: $!";

    while (!eof($fh)) {
        my ($literals, $distances, $lengths) = deflate_decode($fh);
        print $out_fh lz77_decompression($literals, $distances, $lengths);
    }

    close $fh;
    close $out_fh;
}

main();
exit(0);
