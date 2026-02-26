#!/usr/bin/perl

# Author: Trizen
# Date: 14 June 2023
# Edit: 25 February 2026
# https://github.com/trizen

# Compress/decompress files using Burrows-Wheeler Transform (BWT) + Move-to-Front Transform + Run-length encoding + Huffman coding.

# Reference:
#   Data Compression (Summer 2023) - Lecture 13 - BZip2
#   https://youtube.com/watch?v=cvoZbBZ3M2A

# Implementation featuring:
#   1. BWT ENCODE        - O(n * LOOKAHEAD_LEN) space
#   2. HUFFMAN TREE      – O(n log n) binary min-heap priority queue.
#   3. HUFFMAN DECODE    – O(n · avg_code_len) trie traversal.
#   4. BWT INVERSION     – O(n) counting-sort for the next-table.

use 5.036;

use Getopt::Std    qw(getopts);
use File::Basename qw(basename);
use List::Util     qw(max uniq);

use constant {
              PKGNAME       => 'BWT',
              VERSION       => '0.03',
              FORMAT        => 'bwt',
              CHUNK_SIZE    => 1 << 17,    # 128 KiB
              LOOKAHEAD_LEN => 128,
             };

use constant SIGNATURE => uc(FORMAT) . chr(2);

# ---------------------------------------------------------------------------
# CLI boilerplate
# ---------------------------------------------------------------------------

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
        $sig eq SIGNATURE || return;
    }
    return 1;
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

# ---------------------------------------------------------------------------
# Bit-level I/O
# ---------------------------------------------------------------------------

sub read_bit ($fh, $bitstring) {
    if (($$bitstring // '') eq '') {
        $$bitstring = unpack('b*', getc($fh) // return undef);
    }
    chop($$bitstring);
}

sub read_bits ($fh, $bits_len) {
    my $data = '';
    read($fh, $data, $bits_len >> 3);
    $data = unpack('B*', $data);
    while (length($data) < $bits_len) {
        $data .= unpack('B*', getc($fh) // return undef);
    }
    $data = substr($data, 0, $bits_len) if (length($data) > $bits_len);
    return $data;
}

# ---------------------------------------------------------------------------
# Delta coding
# ---------------------------------------------------------------------------

sub delta_encode ($integers, $double = 0) {
    my @deltas;
    my $prev = 0;

    unshift @$integers, scalar(@$integers);

    while (@$integers) {
        my $curr = shift @$integers;
        push @deltas, $curr - $prev;
        $prev = $curr;
    }

    my $bitstring = '';
    foreach my $d (@deltas) {
        if ($d == 0) {
            $bitstring .= '0';
        }
        elsif ($double) {
            my $t = sprintf('%b', abs($d) + 1);
            my $l = sprintf('%b', length($t));
            $bitstring .= '1' . ($d < 0 ? '0' : '1') . ('1' x (length($l) - 1)) . '0' . substr($l, 1) . substr($t, 1);
        }
        else {
            my $t = sprintf('%b', abs($d));
            $bitstring .= '1' . ($d < 0 ? '0' : '1') . ('1' x (length($t) - 1)) . '0' . substr($t, 1);
        }
    }

    pack('B*', $bitstring);
}

sub delta_decode ($fh, $double = 0) {
    my @deltas;
    my $buffer = '';
    my $len    = 0;

    for (my $k = 0 ; $k <= $len ; ++$k) {
        my $bit = read_bit($fh, \$buffer);

        if ($bit eq '0') {
            push @deltas, 0;
        }
        elsif ($double) {
            my $sign = read_bit($fh, \$buffer);
            my $bl   = 0;
            ++$bl while read_bit($fh, \$buffer) eq '1';
            my $bl2 = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. $bl));
            my $int = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. ($bl2 - 1)));
            push @deltas, ($sign eq '1' ? 1 : -1) * ($int - 1);
        }
        else {
            my $sign = read_bit($fh, \$buffer);
            my $n    = 0;
            ++$n while read_bit($fh, \$buffer) eq '1';
            my $d = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. $n));
            push @deltas, ($sign eq '1' ? $d : -$d);
        }

        $len = pop(@deltas) if $k == 0;
    }

    my @acc;
    my $prev = $len;
    foreach my $d (@deltas) {
        $prev += $d;
        push @acc, $prev;
    }
    return \@acc;
}

# ---------------------------------------------------------------------------
# Huffman – binary min-heap priority queue
# ---------------------------------------------------------------------------

sub _heap_push ($heap, $item) {
    push @$heap, $item;
    my $i = $#$heap;
    while ($i > 0) {
        my $p = ($i - 1) >> 1;
        last if ($heap->[$p][1] <= $heap->[$i][1]);
        @{$heap}[$p, $i] = @{$heap}[$i, $p];
        $i = $p;
    }
}

sub _heap_pop ($heap) {
    return pop @$heap if (@$heap == 1);
    my $top = $heap->[0];
    $heap->[0] = pop @$heap;
    my $n = scalar @$heap;
    my $i = 0;
    while (1) {
        my $s = $i;
        my $l = 2 * $i + 1;
        my $r = $l + 1;
        $s = $l if ($l < $n && $heap->[$l][1] < $heap->[$s][1]);
        $s = $r if ($r < $n && $heap->[$r][1] < $heap->[$s][1]);
        last if $s == $i;
        @{$heap}[$i, $s] = @{$heap}[$s, $i];
        $i = $s;
    }
    return $top;
}

sub walk ($node, $code, $h, $rev_h) {
    my $c = $node->[0] // return ($h, $rev_h);
    if (ref $c) { walk($c->[$_], $code . $_, $h, $rev_h) for (0, 1) }
    else        { $h->{$c} = $code; $rev_h->{$code} = $c }
    return ($h, $rev_h);
}

sub mktree_from_freq ($freq) {
    my @heap;
    _heap_push(\@heap, [$_, $freq->{$_}])
      for sort { $a <=> $b } keys %$freq;

    while (@heap > 1) {
        my $x = _heap_pop(\@heap);
        my $y = _heap_pop(\@heap);
        _heap_push(\@heap, [[$x, $y], $x->[1] + $y->[1]]);
    }

    if (@heap == 1 && !ref $heap[0][0]) {
        @heap = ([[$heap[0]], $heap[0][1]]);
    }

    return walk($heap[0], '', {}, {});
}

sub huffman_encode ($bytes, $dict) {
    join('', @{$dict}{@$bytes});
}

# ---------------------------------------------------------------------------
# Huffman decode via trie traversal
# ---------------------------------------------------------------------------

sub _build_trie ($rev_h) {
    my $root = {};
    for my $code (keys %$rev_h) {
        my $node = $root;
        for my $bit (split //, $code) {
            $node->{$bit} //= {};
            $node = $node->{$bit};
        }
        $node->{sym} = $rev_h->{$code};
    }
    return $root;
}

sub huffman_decode ($bits, $rev_h) {
    my $root = _build_trie($rev_h);
    my @result;
    my $node = $root;
    foreach my $i (0 .. length($bits) - 1) {
        my $bit = substr($bits, $i, 1);
        $node = $node->{$bit};
        if (exists $node->{sym}) {
            push @result, $node->{sym};
            $node = $root;
        }
    }
    return \@result;
}

sub create_huffman_entry ($bytes, $out_fh) {
    my %freq;
    ++$freq{$_} for @$bytes;

    my ($h, $rev_h) = mktree_from_freq(\%freq);
    my $enc        = huffman_encode($bytes, $h);
    my $max_symbol = max(keys %freq) // 0;
    say "Max symbol: $max_symbol\n";

    my @freqs;
    push @freqs, ($freq{$_} // 0) for 0 .. $max_symbol;

    print $out_fh delta_encode(\@freqs);
    print $out_fh pack('N',  length($enc));
    print $out_fh pack('B*', $enc);
}

sub decode_huffman_entry ($fh) {
    my @freqs = @{delta_decode($fh)};

    my %freq;
    for my $i (0 .. $#freqs) {
        $freq{$i} = $freqs[$i] if $freqs[$i];
    }

    my (undef, $rev_dict) = mktree_from_freq(\%freq);
    my $enc_len = unpack('N', join('', map { getc($fh) // die "error" } 1 .. 4));
    say "Encoded length: $enc_len\n";

    return (
            ($enc_len > 0)
            ? huffman_decode(read_bits($fh, $enc_len), $rev_dict)
            : []
           );
}

# ---------------------------------------------------------------------------
# Move-to-Front
# ---------------------------------------------------------------------------

sub mtf_encode ($bytes, $alphabet = [0 .. 255]) {
    my @C;
    my @table;
    @table[@$alphabet] = (0 .. $#{$alphabet});

    for my $c (@$bytes) {
        push @C, (my $index = $table[$c]);
        unshift @$alphabet, splice(@$alphabet, $index, 1);
        @table[@{$alphabet}[0 .. $index]] = (0 .. $index);
    }
    return \@C;
}

sub mtf_decode ($encoded, $alphabet = [0 .. 255]) {
    my @S;
    for my $p (@$encoded) {
        push @S, $alphabet->[$p];
        unshift @$alphabet, splice(@$alphabet, $p, 1);
    }
    return \@S;
}

# ---------------------------------------------------------------------------
# BWT construction
# ---------------------------------------------------------------------------

sub bwt_sort ($s) {    # O(n * LOOKAHEAD_LEN) space (fast)
    my $len      = length($s);
    my $double_s = $s . $s;      # Pre-compute doubled string

    # Schwartzian transform with optimized sorting
    return [
        map { $_->[1] }
        sort {
            ($a->[0] cmp $b->[0])
              || do {
                my ($cmp, $s_len) = (0, LOOKAHEAD_LEN << 1);
                while (1) {
                    ($cmp = substr($double_s, $a->[1], $s_len) cmp substr($double_s, $b->[1], $s_len)) && last;
                    $s_len <<= 1;
                }
                $cmp;
            }
        }
        map {
            my $pos = $_;
            my $end = $pos + LOOKAHEAD_LEN;

            # Handle wraparound efficiently
            my $t =
              ($end <= $len)
              ? substr($s,        $pos, LOOKAHEAD_LEN)
              : substr($double_s, $pos, LOOKAHEAD_LEN);

            [$t, $pos]
          } 0 .. $len - 1
    ];
}

sub bwt_encode ($s) {

    my $bwt = bwt_sort($s);
    my $len = length($s);

    my $ret = '';
    my $idx = 0;

    my $i = 0;
    foreach my $pos (@$bwt) {
        $ret .= substr($s, $pos - 1, 1);
        $idx = $i if !$pos;
        ++$i;
    }

    return ($ret, $idx);
}

# ---------------------------------------------------------------------------
# BWT inversion with counting sort
# ---------------------------------------------------------------------------

sub bwt_decode ($bwt, $idx) {
    my @L = unpack('C*', $bwt);
    my $n = scalar @L;

    my @freq = (0) x 256;
    $freq[$_]++ for @L;

    my @cumul = (0) x 257;
    $cumul[$_ + 1] = $cumul[$_] + $freq[$_] for 0 .. 255;

    my @next;
    my @cnt = (0) x 256;
    for my $i (0 .. $n - 1) {
        $next[$cumul[$L[$i]] + $cnt[$L[$i]]++] = $i;
    }

    my @dec;
    my $i = $idx;
    for (1 .. $n) {
        $i = $next[$i];
        push @dec, $L[$i];
    }

    return pack('C*', @dec);
}

# ---------------------------------------------------------------------------
# Run-length encoding stages
# ---------------------------------------------------------------------------

sub rle4_encode ($bytes) {
    my @rle;
    my $end  = $#{$bytes};
    my $prev = -1;
    my $run  = 0;

    for (my $i = 0 ; $i <= $end ; ++$i) {

        if ($bytes->[$i] == $prev) {
            ++$run;
        }
        else {
            $run = 1;
        }

        push @rle, $bytes->[$i];
        $prev = $bytes->[$i];

        if ($run >= 4) {
            $run = 0;
            ++$i;
            while ($run < 255 && $i <= $end && $bytes->[$i] == $prev) {
                ++$run;
                ++$i;
            }
            push @rle, $run;
            $run = 1;
            if ($i <= $end) {
                $prev = $bytes->[$i];
                push @rle, $bytes->[$i];
            }
        }
    }
    return \@rle;
}

sub rle4_decode ($bytes) {
    my @dec  = $bytes->[0];
    my $end  = $#{$bytes};
    my $prev = $bytes->[0];
    my $run  = 1;

    for (my $i = 1 ; $i <= $end ; ++$i) {

        if ($bytes->[$i] == $prev) {
            ++$run;
        }
        else {
            $run = 1;
        }

        push @dec, $bytes->[$i];
        $prev = $bytes->[$i];

        if ($run >= 4) {
            if (++$i <= $end) {
                $run = $bytes->[$i];
                push @dec, ($prev) x $run;
            }
            $run = 0;
        }
    }
    return \@dec;
}

sub rle_encode ($bytes) {
    my @rle;
    my $end = $#{$bytes};

    for (my $i = 0 ; $i <= $end ; ++$i) {
        my $run = 0;
        while ($i <= $end && $bytes->[$i] == 0) { ++$run; ++$i }
        if ($run >= 1) {
            my $t = sprintf('%b', $run + 1);
            push @rle, split(//, substr($t, 1));
        }
        push @rle, $bytes->[$i] + 1 if $i <= $end;
    }
    return \@rle;
}

sub rle_decode ($rle) {
    my @dec;
    my $end = $#{$rle};

    for (my $i = 0 ; $i <= $end ; ++$i) {
        my $k = $rle->[$i];
        if ($k == 0 || $k == 1) {
            my $run = 1;
            while ($i <= $end && ($k == 0 || $k == 1)) {
                ($run <<= 1) |= $k;
                $k = $rle->[++$i];
            }
            push @dec, (0) x ($run - 1);
        }
        push @dec, $k - 1 if $i <= $end;
    }
    return \@dec;
}

# ---------------------------------------------------------------------------
# Alphabet encoding / decoding
# ---------------------------------------------------------------------------

sub encode_alphabet ($alphabet) {
    my %table;
    @table{@$alphabet} = ();

    my $populated = 0;
    my @marked;

    for (my $i = 0 ; $i <= 255 ; $i += 32) {
        my $enc = 0;
        $enc |= 1 << $_ for grep { exists $table{$i + $_} } 0 .. 31;

        if ($enc == 0) { $populated <<= 1 }
        else           { ($populated <<= 1) |= 1; push @marked, $enc }
    }

    my $delta = delta_encode([@marked], 1);

    say "Populated : ", sprintf('%08b', $populated);
    say "Marked    : @marked";
    say "Delta len : ", length($delta);

    return chr($populated) . $delta;
}

sub decode_alphabet ($fh) {
    my @populated = split(//, sprintf('%08b', ord(getc($fh))));
    my $marked    = delta_decode($fh, 1);

    my @alphabet;
    for (my $i = 0 ; $i <= 255 ; $i += 32) {
        if (shift @populated) {
            my $m = shift @$marked;
            for my $j (0 .. 31) {
                push @alphabet, $i + $j if $m & 1;
                $m >>= 1;
            }
        }
    }
    return \@alphabet;
}

# ---------------------------------------------------------------------------
# Top-level compression / decompression passes
# ---------------------------------------------------------------------------

sub compression ($chunk, $out_fh) {
    my $rle1 = rle4_encode([unpack('C*', $chunk)]);
    my ($bwt, $idx) = bwt_encode(pack('C*', @$rle1));

    say "BWT index = $idx";

    my @bytes        = unpack('C*', $bwt);
    my @alphabet     = sort { $a <=> $b } uniq(@bytes);
    my $alphabet_enc = encode_alphabet(\@alphabet);

    my $mtf = mtf_encode(\@bytes, [@alphabet]);
    my $rle = rle_encode($mtf);

    print $out_fh pack('N', $idx);
    print $out_fh $alphabet_enc;
    create_huffman_entry($rle, $out_fh);
}

sub decompression ($fh, $out_fh) {
    my $idx      = unpack('N', join('', map { getc($fh) // return undef } 1 .. 4));
    my $alphabet = decode_alphabet($fh);

    say "BWT index = $idx";
    say "Alphabet size: ", scalar(@$alphabet);

    my $rle  = decode_huffman_entry($fh);
    my $mtf  = rle_decode($rle);
    my $bwt  = mtf_decode($mtf, $alphabet);
    my $rle4 = bwt_decode(pack('C*', @$bwt), $idx);
    my $data = rle4_decode([unpack('C*', $rle4)]);

    print $out_fh pack('C*', @$data);
}

# ---------------------------------------------------------------------------
# File-level entry points
# ---------------------------------------------------------------------------

sub compress_file ($input, $output) {
    open my $fh, '<:raw', $input
      or die "Can't open file <<$input>> for reading: $!";
    open my $out_fh, '>:raw', $output
      or die "Can't open file <<$output>> for writing: $!";

    print $out_fh SIGNATURE;
    while (read($fh, (my $chunk), CHUNK_SIZE)) {
        compression($chunk, $out_fh);
    }
    close $out_fh;
}

sub decompress_file ($input, $output) {
    open my $fh, '<:raw', $input
      or die "Can't open file <<$input>> for reading: $!";

    valid_archive($fh)
      || die "$0: file `$input' is not a \U${\FORMAT}\E v${\VERSION} archive!\n";

    open my $out_fh, '>:raw', $output
      or die "Can't open file <<$output>> for writing: $!";

    while (!eof($fh)) {
        decompression($fh, $out_fh);
    }
    close $fh;
    close $out_fh;
}

main();
exit 0;
