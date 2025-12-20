#!/usr/bin/perl

# Author: Trizen
# Date: 15 June 2023
# Edit: 20 June 2023
# https://github.com/trizen

# Compress/decompress files using Burrows-Wheeler Transform (BWT) + Move-to-front transform (MTF) + LZ77 compression (LZSS) + Huffman coding.

# Encoding the literals and the pointers using a DEFLATE-like approach.

# References:
#   Data Compression (Summer 2023) - Lecture 11 - DEFLATE (gzip)
#   https://youtube.com/watch?v=SJPvNi4HrWQ
#
#   Data Compression (Summer 2023) - Lecture 13 - BZip2
#   https://youtube.com/watch?v=cvoZbBZ3M2A

use 5.036;
use Getopt::Std    qw(getopts);
use File::Basename qw(basename);
use List::Util     qw(max uniq);
use POSIX          qw(ceil log2);

use constant {
    PKGNAME => 'BWLZ',
    VERSION => '0.05',
    FORMAT  => 'bwlz',

    CHUNK_SIZE    => 1 << 17,    # higher value = better compression
    LOOKAHEAD_LEN => 128,
};

# Container signature
use constant SIGNATURE => uc(FORMAT) . chr(5);

# [distance value, offset bits]
my @DISTANCE_SYMBOLS = map { [$_, 0] } (0 .. 4);

until ($DISTANCE_SYMBOLS[-1][0] > CHUNK_SIZE) {
    push @DISTANCE_SYMBOLS, [int($DISTANCE_SYMBOLS[-1][0] * (4 / 3)), $DISTANCE_SYMBOLS[-1][1] + 1];
    push @DISTANCE_SYMBOLS, [int($DISTANCE_SYMBOLS[-1][0] * (3 / 2)), $DISTANCE_SYMBOLS[-1][1]];
}

# [length, offset bits]
my @LENGTH_SYMBOLS = ((map { [$_, 0] } (4 .. 10)));

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

my @DISTANCE_INDICES;

foreach my $i (0 .. $#DISTANCE_SYMBOLS) {
    my ($min, $bits) = @{$DISTANCE_SYMBOLS[$i]};
    foreach my $k ($min .. $min + (1 << $bits) - 1) {
        last if ($k > CHUNK_SIZE);
        $DISTANCE_INDICES[$k] = $i;
    }
}

my @LENGTH_INDICES;

foreach my $i (0 .. $#LENGTH_SYMBOLS) {
    my ($min, $bits) = @{$LENGTH_SYMBOLS[$i]};
    foreach my $k ($min .. $min + (1 << $bits) - 1) {
        $LENGTH_INDICES[$k] = $i;
    }
}

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

sub valid_archive {
    my ($fh) = @_;

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

    if (length($data) > $bits_len) {
        $data = substr($data, 0, $bits_len);
    }

    return $data;
}

sub delta_encode ($integers, $double = 0) {

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
        elsif ($double) {
            my $t = sprintf('%b', abs($d) + 1);
            my $l = sprintf('%b', length($t));
            $bitstring .= '1' . (($d < 0) ? '0' : '1') . ('1' x (length($l) - 1)) . '0' . substr($l, 1) . substr($t, 1);
        }
        else {
            my $t = sprintf('%b', abs($d));
            $bitstring .= '1' . (($d < 0) ? '0' : '1') . ('1' x (length($t) - 1)) . '0' . substr($t, 1);
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
            my $bit = read_bit($fh, \$buffer);

            my $bl = 0;
            ++$bl while (read_bit($fh, \$buffer) eq '1');

            my $bl2 = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. $bl));
            my $int = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. ($bl2 - 1)));

            push @deltas, ($bit eq '1' ? 1 : -1) * ($int - 1);
        }
        else {
            my $bit = read_bit($fh, \$buffer);
            my $n   = 0;
            ++$n while (read_bit($fh, \$buffer) eq '1');
            my $d = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. $n));
            push @deltas, ($bit eq '1' ? $d : -$d);
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

sub lz77_compression ($str, $uncompressed, $indices, $lengths) {

    my $la = 0;

    my $prefix = '';
    my @chars  = split(//, $str);
    my $end    = $#chars;

    my $min_len = $LENGTH_SYMBOLS[0][0];
    my $max_len = $LENGTH_SYMBOLS[-1][0];

    my %literal_freq;
    my %distance_freq;

    my $literal_count  = 0;
    my $distance_count = 0;

    while ($la <= $end) {

        my $n = 1;
        my $p = length($prefix);
        my $tmp;

        my $token = $chars[$la];

        while (    $n <= $max_len
               and $la + $n <= $end
               and ($tmp = rindex($prefix, $token, $p)) >= 0) {
            $p = $tmp;
            $token .= $chars[$la + $n];
            ++$n;
        }

        my $enc_bits_len     = 0;
        my $literal_bits_len = 0;

        if ($n > $min_len) {

            my $dist = $DISTANCE_SYMBOLS[$DISTANCE_INDICES[$la - $p]];
            $enc_bits_len += $dist->[1] + ceil(log2((1 + $distance_count) / (1 + ($distance_freq{$dist->[0]} // 0))));

            my $len_idx = $LENGTH_INDICES[$n - 1];
            my $len     = $LENGTH_SYMBOLS[$len_idx];

            $enc_bits_len += $len->[1] + ceil(log2((1 + $literal_count) / (1 + ($literal_freq{$len_idx + 256} // 0))));

            my %freq;
            foreach my $c (unpack('C*', substr($prefix, $p, $n - 1) . $chars[$la + $n - 1])) {
                ++$freq{$c};
                $literal_bits_len += ceil(log2(($n + $literal_count) / ($freq{$c} + ($literal_freq{$c} // 0))));
            }
        }

        if ($n > $min_len and $enc_bits_len < $literal_bits_len) {

            push @$lengths,      $n - 1;
            push @$indices,      $la - $p;
            push @$uncompressed, undef;

            my $dist_idx = $DISTANCE_INDICES[$la - $p];
            my $dist     = $DISTANCE_SYMBOLS[$dist_idx];

            ++$distance_count;
            ++$distance_freq{$dist->[0]};

            ++$literal_count;
            ++$literal_freq{$LENGTH_INDICES[$n - 1] + 256};

            $la += $n - 1;
            $prefix .= substr($token, 0, -1);
        }
        else {
            my @bytes = unpack('C*', substr($prefix, $p, $n - 1) . $chars[$la + $n - 1]);

            push @$uncompressed, @bytes;
            push @$lengths, (0) x scalar(@bytes);
            push @$indices, (0) x scalar(@bytes);

            ++$literal_freq{$_} for @bytes;

            $literal_count += $n;
            $la            += $n;
            $prefix .= $token;
        }
    }

    return;
}

sub lz77_decompression ($literals, $distances, $lengths) {

    my $chunk  = '';
    my $offset = 0;

    foreach my $i (0 .. $#$literals) {
        if ($lengths->[$i] != 0) {
            $chunk .= substr($chunk, $offset - $distances->[$i], $lengths->[$i]);
            $offset += $lengths->[$i];
        }
        else {
            $chunk .= chr($literals->[$i]);
            $offset += 1;
        }
    }

    return $chunk;
}

# produce encode and decode dictionary from a tree
sub walk ($node, $code, $h, $rev_h) {

    my $c = $node->[0] // return ($h, $rev_h);
    if (ref $c) { walk($c->[$_], $code . $_, $h, $rev_h) for ('0', '1') }
    else        { $h->{$c} = $code; $rev_h->{$code} = $c }

    return ($h, $rev_h);
}

# make a tree, and return resulting dictionaries
sub mktree_from_freq ($freq) {

    my @nodes = map { [$_, $freq->{$_}] } sort { $a <=> $b } keys %$freq;

    do {    # poor man's priority queue
        @nodes = sort { $a->[1] <=> $b->[1] } @nodes;
        my ($x, $y) = splice(@nodes, 0, 2);
        if (defined($x)) {
            if (defined($y)) {
                push @nodes, [[$x, $y], $x->[1] + $y->[1]];
            }
            else {
                push @nodes, [[$x], $x->[1]];
            }
        }
    } while (@nodes > 1);

    walk($nodes[0], '', {}, {});
}

sub huffman_encode ($bytes, $dict) {
    join('', @{$dict}{@$bytes});
}

sub huffman_decode ($bits, $hash) {
    local $" = '|';
    [split(' ', $bits =~ s/(@{[sort { length($a) <=> length($b) } keys %{$hash}]})/$hash->{$1} /gr)];    # very fast
}

sub create_huffman_entry ($bytes, $out_fh) {

    my %freq;
    ++$freq{$_} for @$bytes;

    my ($h, $rev_h) = mktree_from_freq(\%freq);
    my $enc = huffman_encode($bytes, $h);

    my $max_symbol = max(keys %freq) // 0;
    say "Max symbol: $max_symbol";

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

sub deflate_encode ($literals, $distances, $lengths, $out_fh) {

    my @len_symbols;
    my @dist_symbols;
    my $offset_bits = '';

    foreach my $j (0 .. $#{$literals}) {

        if ($lengths->[$j] == 0) {
            push @len_symbols, $literals->[$j];
            next;
        }

        my $len  = $lengths->[$j];
        my $dist = $distances->[$j];

        {
            my $len_idx = $LENGTH_INDICES[$len];
            my ($min, $bits) = @{$LENGTH_SYMBOLS[$len_idx]};

            push @len_symbols, $len_idx + 256;

            if ($bits > 0) {
                $offset_bits .= sprintf('%0*b', $bits, $len - $min);
            }
        }

        {
            my $dist_idx = $DISTANCE_INDICES[$dist];
            my ($min, $bits) = @{$DISTANCE_SYMBOLS[$dist_idx]};

            push @dist_symbols, $dist_idx;

            if ($bits > 0) {
                $offset_bits .= sprintf('%0*b', $bits, $dist - $min);
            }
        }
    }

    create_huffman_entry(\@len_symbols,  $out_fh);
    create_huffman_entry(\@dist_symbols, $out_fh);
    print $out_fh pack('B*', $offset_bits);
}

sub deflate_decode ($fh) {

    my $len_symbols  = decode_huffman_entry($fh);
    my $dist_symbols = decode_huffman_entry($fh);

    my $bits_len = 0;

    foreach my $i (@$dist_symbols) {
        $bits_len += $DISTANCE_SYMBOLS[$i][1];
    }

    foreach my $i (@$len_symbols) {
        if ($i >= 256) {
            $bits_len += $LENGTH_SYMBOLS[$i - 256][1];
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
            push @lengths,   $LENGTH_SYMBOLS[$i - 256][0] + oct('0b' . substr($bits, 0, $LENGTH_SYMBOLS[$i - 256][1], ''));
            push @distances, $DISTANCE_SYMBOLS[$dist][0] + oct('0b' . substr($bits, 0, $DISTANCE_SYMBOLS[$dist][1], ''));
        }
        else {
            push @literals,  $i;
            push @lengths,   0;
            push @distances, 0;
        }
    }

    return (\@literals, \@distances, \@lengths);
}

sub mtf_encode ($bytes, $alphabet = [0 .. 255]) {

    my @C;

    my @table;
    @table[@$alphabet] = (0 .. $#{$alphabet});

    foreach my $c (@$bytes) {
        push @C, (my $index = $table[$c]);
        unshift(@$alphabet, splice(@$alphabet, $index, 1));
        @table[@{$alphabet}[0 .. $index]] = (0 .. $index);
    }

    return \@C;
}

sub mtf_decode ($encoded, $alphabet = [0 .. 255]) {

    my @S;

    foreach my $p (@$encoded) {
        push @S, $alphabet->[$p];
        unshift(@$alphabet, splice(@$alphabet, $p, 1));
    }

    return \@S;
}

sub bwt_sort ($s) {    # O(n * LOOKAHEAD_LEN) space (fast)
    my $len      = length($s);
    my $double_s = $s . $s;                  # Pre-compute doubled string

    # Schwartzian transform with optimized sorting
    return [
        map  { $_->[1] }
        sort { ($a->[0] cmp $b->[0]) || (substr($double_s, $a->[1], $len) cmp substr($double_s, $b->[1], $len)) }
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

sub bwt_decode ($bwt, $idx) {    # fast inversion

    my @tail = split(//, $bwt);
    my @head = sort @tail;

    my %indices;
    foreach my $i (0 .. $#tail) {
        push @{$indices{$tail[$i]}}, $i;
    }

    my @table;
    foreach my $v (@head) {
        push @table, shift(@{$indices{$v}});
    }

    my $dec = '';
    my $i   = $idx;

    for (1 .. scalar(@head)) {
        $dec .= $head[$i];
        $i = $table[$i];
    }

    return $dec;
}

sub rle4_encode ($bytes) {    # RLE1

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
            $i += 1;

            while ($run < 254 and $i <= $end and $bytes->[$i] == $prev) {
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

sub rle4_decode ($bytes) {    # RLE1

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
                push @dec, (($prev) x $run);
            }

            $run = 0;
        }
    }

    return \@dec;
}

sub rle_encode ($bytes) {    # RLE2

    my @rle;
    my $end = $#{$bytes};

    for (my $i = 0 ; $i <= $end ; ++$i) {

        my $run = 0;
        while ($i <= $end and $bytes->[$i] == 0) {
            ++$run;
            ++$i;
        }

        if ($run >= 1) {
            my $t = sprintf('%b', $run + 1);
            push @rle, split(//, substr($t, 1));
        }

        if ($i <= $end) {
            push @rle, $bytes->[$i] + 1;
        }
    }

    return \@rle;
}

sub rle_decode ($rle) {    # RLE2

    my @dec;
    my $end = $#{$rle};

    for (my $i = 0 ; $i <= $end ; ++$i) {
        my $k = $rle->[$i];

        if ($k == 0 or $k == 1) {
            my $run = 1;
            while (($i <= $end) and ($k == 0 or $k == 1)) {
                ($run <<= 1) |= $k;
                $k = $rle->[++$i];
            }
            push @dec, (0) x ($run - 1);
        }

        if ($i <= $end) {
            push @dec, $k - 1;
        }
    }

    return \@dec;
}

sub encode_alphabet ($alphabet) {

    my %table;
    @table{@$alphabet} = ();

    my $populated = 0;
    my @marked;

    for (my $i = 0 ; $i <= 255 ; $i += 32) {

        my $enc = 0;
        foreach my $j (0 .. 31) {
            if (exists($table{$i + $j})) {
                $enc |= 1 << $j;
            }
        }

        if ($enc == 0) {
            $populated <<= 1;
        }
        else {
            ($populated <<= 1) |= 1;
            push @marked, $enc;
        }
    }

    my $delta = delta_encode([@marked], 1);

    say "Populated : ", sprintf('%08b', $populated);
    say "Marked    : @marked";
    say "Delta len : ", length($delta);

    my $encoded = '';
    $encoded .= chr($populated);
    $encoded .= $delta;
    return $encoded;
}

sub decode_alphabet ($fh) {

    my @populated = split(//, sprintf('%08b', ord(getc($fh) // die "error")));
    my $marked    = delta_decode($fh, 1);

    my @alphabet;
    for (my $i = 0 ; $i <= 255 ; $i += 32) {
        if (shift(@populated)) {
            my $m = shift(@$marked);
            foreach my $j (0 .. 31) {
                if ($m & 1) {
                    push @alphabet, $i + $j;
                }
                $m >>= 1;
            }
        }
    }

    return \@alphabet;
}

sub lzss_compression ($data, $out_fh) {
    my (@uncompressed, @indices, @lengths);
    lz77_compression($data, \@uncompressed, \@indices, \@lengths);

    my $est_ratio = length($data) / (scalar(@uncompressed) + scalar(@lengths) + 2 * scalar(@indices));
    say "\nEst. ratio: ", $est_ratio, " (", scalar(@uncompressed), " uncompressed bytes)";

    deflate_encode(\@uncompressed, \@indices, \@lengths, $out_fh);
}

sub lzss_decompression ($fh) {
    my ($uncompressed, $indices, $lengths) = deflate_decode($fh);
    lz77_decompression($uncompressed, $indices, $lengths);
}

sub compression ($chunk, $out_fh) {

    my @chunk_bytes = unpack('C*', $chunk);
    my $data        = pack('C*', @{rle4_encode(\@chunk_bytes)});

    my ($bwt, $idx) = bwt_encode($data);

    my @bytes    = unpack('C*', $bwt);
    my @alphabet = sort { $a <=> $b } uniq(@bytes);

    my $enc_bytes = mtf_encode(\@bytes, [@alphabet]);

    if (max(@$enc_bytes) < 255) {
        print $out_fh chr(1);
        $enc_bytes = rle_encode($enc_bytes);
    }
    else {
        print $out_fh chr(0);
        $enc_bytes = rle4_encode($enc_bytes);
    }

    print $out_fh pack('N', $idx);
    print $out_fh encode_alphabet(\@alphabet);
    lzss_compression(pack('C*', @$enc_bytes), $out_fh);
}

sub decompression ($fh, $out_fh) {

    my $rle_encoded = ord(getc($fh) // die "error");
    my $idx         = unpack('N', join('', map { getc($fh) // die "error" } 1 .. 4));
    my $alphabet    = decode_alphabet($fh);

    my $dec   = lzss_decompression($fh);
    my $bytes = [unpack('C*', $dec)];

    if ($rle_encoded) {
        $bytes = rle_decode($bytes);
    }
    else {
        $bytes = rle4_decode($bytes);
    }

    $bytes = mtf_decode($bytes, [@$alphabet]);

    print $out_fh pack('C*', @{rle4_decode([unpack('C*', bwt_decode(pack('C*', @$bytes), $idx))])});
}

# Compress file
sub compress_file ($input, $output) {

    open my $fh, '<:raw', $input
      or die "Can't open file <<$input>> for reading: $!";

    my $header = SIGNATURE;

    # Open the output file for writing
    open my $out_fh, '>:raw', $output
      or die "Can't open file <<$output>> for write: $!";

    # Print the header
    print $out_fh $header;

    # Compress data
    while (read($fh, (my $chunk), CHUNK_SIZE)) {
        compression($chunk, $out_fh);
    }

    # Close the file
    close $out_fh;
}

# Decompress file
sub decompress_file ($input, $output) {

    # Open and validate the input file
    open my $fh, '<:raw', $input
      or die "Can't open file <<$input>> for reading: $!";

    valid_archive($fh) || die "$0: file `$input' is not a \U${\FORMAT}\E v${\VERSION} archive!\n";

    # Open the output file
    open my $out_fh, '>:raw', $output
      or die "Can't open file <<$output>> for writing: $!";

    while (!eof($fh)) {
        decompression($fh, $out_fh);
    }

    # Close the file
    close $fh;
    close $out_fh;
}

main();
exit(0);
