#!/usr/bin/perl

# Author: Trizen
# Date: 15 June 2023
# Edit: 16 June 2023
# https://github.com/trizen

# Compress/decompress files using Burrows-Wheeler Transform (BWT) + LZ77 compression + Huffman coding.

# Encoding the distances/indices using a DEFLATE-like approach.

use 5.036;
use Getopt::Std    qw(getopts);
use File::Basename qw(basename);
use List::Util     qw(max uniq);

use constant {
    PKGNAME => 'BWLZ',
    VERSION => '0.02',
    FORMAT  => 'bwlz',

    COMPRESSED_BYTE   => chr(1),
    UNCOMPRESSED_BYTE => chr(0),
    CHUNK_SIZE        => 1 << 17,    # higher value = better compression
    LOOKAHEAD_LEN     => 128,
};

use constant {SIGNATURE => "BWLZ" . chr(2)};

# [distance value, offset bits]
my @DISTANCE_SYMBOLS = ([0, 0], [1, 0], [2, 0], [3, 0], [4, 0]);

until ($DISTANCE_SYMBOLS[-1][0] > CHUNK_SIZE) {
    push @DISTANCE_SYMBOLS, [int($DISTANCE_SYMBOLS[-1][0] * (4 / 3)), $DISTANCE_SYMBOLS[-1][1] + 1];
    push @DISTANCE_SYMBOLS, [int($DISTANCE_SYMBOLS[-1][0] * (3 / 2)), $DISTANCE_SYMBOLS[-1][1]];
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

        lz77h_decompress_file($input, $output)
          || die "$0: error: decompression failed!\n";
    }
    elsif ($input !~ $ext || (defined($output) && $output =~ $ext)) {
        $output //= basename($input) . '.' . FORMAT;
        lz77h_compress_file($input, $output)
          || die "$0: error: compression failed!\n";
    }
    else {
        warn "$0: don't know what to do...\n";
        usage(1);
    }
}

sub lz77_compression ($str, $uncompressed, $indices, $lengths) {

    my $la = 0;

    my $prefix = '';
    my @chars  = split(//, $str);
    my $end    = $#chars;

    while ($la <= $end) {

        my $n = 1;
        my $p = 0;
        my $tmp;

        my $token = $chars[$la];

        while (    $n < 255
               and $la + $n <= $end
               and ($tmp = index($prefix, $token, $p)) >= 0) {
            $p = $tmp;
            $token .= $chars[$la + $n];
            ++$n;
        }

        --$n;
        push @$indices,      $p;
        push @$lengths,      $n;
        push @$uncompressed, ord($chars[$la + $n]);
        $la += $n + 1;
        $prefix .= $token;
    }

    return;
}

sub lz77_decompression ($uncompressed, $indices, $lengths) {

    my $chunk = '';

    foreach my $i (0 .. $#{$uncompressed}) {
        $chunk .= substr($chunk, $indices->[$i], $lengths->[$i]) . $uncompressed->[$i];
    }

    return $chunk;
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

    pack('B*', $bitstring);
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
    my $enc = '';
    for (@$bytes) {
        $enc .= $dict->{$_} // die "bad char: $_";
    }
    return $enc;
}

sub huffman_decode ($bits, $hash) {
    local $" = '|';
    $bits =~ s/(@{[sort { length($a) <=> length($b) } keys %{$hash}]})/$hash->{$1}/gr;    # very fast
}

sub create_huffman_entry ($bytes, $out_fh) {

    my %freq;
    ++$freq{$_} for @$bytes;

    my ($h, $rev_h) = mktree_from_freq(\%freq);
    my $enc = huffman_encode($bytes, $h);

    my $max_symbol = max(@$bytes);
    say "Max symbol: $max_symbol";

    my @freqs;
    my $codes = '';

    foreach my $i (0 .. $max_symbol) {
        push @freqs, $freq{$i} // 0;
    }

    print $out_fh delta_encode(\@freqs);
    print $out_fh pack("N",  length($enc));
    print $out_fh pack("B*", $enc);
}

sub decode_huffman_entry ($fh) {

    my @codes;
    my $codes_len = 0;

    my @freqs = @{delta_decode($fh)};

    my %freq;
    foreach my $i (0 .. $#freqs) {
        if ($freqs[$i]) {
            $freq{$i} = $freqs[$i];
        }
    }

    my (undef, $rev_dict) = mktree_from_freq(\%freq);

    foreach my $k (keys %$rev_dict) {
        $rev_dict->{$k} = chr($rev_dict->{$k});
    }

    my $enc_len = unpack('N', join('', map { getc($fh) } 1 .. 4));

    if ($enc_len > 0) {
        return huffman_decode(read_bits($fh, $enc_len), $rev_dict);
    }

    return '';
}

sub encode_distances ($distances, $out_fh) {

    my @symbols;
    my $offset_bits = '';

    foreach my $dist (@$distances) {
        foreach my $i (0 .. $#DISTANCE_SYMBOLS) {
            if ($DISTANCE_SYMBOLS[$i][0] > $dist) {
                push @symbols, $i - 1;

                if ($DISTANCE_SYMBOLS[$i - 1][1] > 0) {
                    $offset_bits .= sprintf('%0*b', $DISTANCE_SYMBOLS[$i - 1][1], $dist - $DISTANCE_SYMBOLS[$i - 1][0]);
                }
                last;
            }
        }
    }

    create_huffman_entry(\@symbols, $out_fh);
    print $out_fh pack('B*', $offset_bits);
}

sub decode_distances ($fh) {

    my @symbols  = unpack('C*', decode_huffman_entry($fh));
    my $bits_len = 0;

    foreach my $i (@symbols) {
        $bits_len += $DISTANCE_SYMBOLS[$i][1];
    }

    my $bits = read_bits($fh, $bits_len);

    my @distances;
    foreach my $i (@symbols) {
        push @distances, $DISTANCE_SYMBOLS[$i][0] + oct('0b' . substr($bits, 0, $DISTANCE_SYMBOLS[$i][1], ''));
    }

    return \@distances;
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

sub bwt_lookahead ($s) {    # O(n) space (moderately fast)
    [
     sort {
         my $t = substr($s, $a, LOOKAHEAD_LEN);
         my $u = substr($s, $b, LOOKAHEAD_LEN);

         if (length($t) < LOOKAHEAD_LEN) {
             $t .= substr($s, 0, ($a < LOOKAHEAD_LEN) ? $a : (LOOKAHEAD_LEN - length($t)));
         }

         if (length($u) < LOOKAHEAD_LEN) {
             $u .= substr($s, 0, ($b < LOOKAHEAD_LEN) ? $b : (LOOKAHEAD_LEN - length($u)));
         }

         ($t cmp $u) || ((substr($s, $a) . substr($s, 0, $a)) cmp(substr($s, $b) . substr($s, 0, $b)))
       } 0 .. length($s) - 1
    ];
}

sub bwt_balanced ($s) {    # O(n * LOOKAHEAD_LEN) space (fast)
    [
     map { $_->[1] } sort {
              ($a->[0] cmp $b->[0])
           || ((substr($s, $a->[1]) . substr($s, 0, $a->[1])) cmp(substr($s, $b->[1]) . substr($s, 0, $b->[1])))
       }
       map {
         my $t = substr($s, $_, LOOKAHEAD_LEN);

         if (length($t) < LOOKAHEAD_LEN) {
             $t .= substr($s, 0, ($_ < LOOKAHEAD_LEN) ? $_ : (LOOKAHEAD_LEN - length($t)));
         }

         [$t, $_]
       } 0 .. length($s) - 1
    ];
}

sub bwt_encode ($s) {

    #my $bwt = bwt_lookahead($s);
    my $bwt = bwt_balanced($s);

    my $ret    = join('', map { substr($s, $_ - 1, 1) } @$bwt);
    my $prefix = substr($s, 0, LOOKAHEAD_LEN);
    my $len    = length($prefix);

    my $idx = 0;
    foreach my $i (@$bwt) {

        my $lookahead = substr($s, $i, $len);

        if (length($lookahead) < $len) {
            $lookahead .= substr($s, 0, $len - length($lookahead));
        }

        if ($lookahead eq $prefix) {
            my $row = substr($s, $i) . substr($s, 0, $i);
            if ($row eq $s) {
                last;
            }
        }
        ++$idx;
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

    my $delta = delta_encode([@marked]);

    say "Populated : ", sprintf('%08b', $populated);
    say "Marked    : @marked";
    say "Delta len : ", length($delta);

    my $encoded = '';
    $encoded .= chr($populated);
    $encoded .= $delta;
    return $encoded;
}

sub decode_alphabet ($fh) {

    my @populated = split(//, sprintf('%08b', ord(getc($fh))));
    my $marked    = delta_decode($fh);

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

# Compress file
sub lz77h_compress_file ($input, $output) {

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

        my @chunk_bytes = unpack('C*', $chunk);
        my $data        = pack('C*', @{rle4_encode(\@chunk_bytes)});

        my ($bwt, $idx) = bwt_encode($data);

        my @bytes    = unpack('C*', $bwt);
        my @alphabet = sort { $a <=> $b } uniq(@bytes);

        my $enc_bytes = mtf_encode(\@bytes, [@alphabet]);

        if ($alphabet[-1] < 255) {
            $enc_bytes = rle_encode($enc_bytes);
        }

        $data = pack('C*', @$enc_bytes);

        my (@uncompressed, @indices, @lengths);
        lz77_compression($data, \@uncompressed, \@indices, \@lengths);

        my $est_ratio = length($chunk) / (4 * scalar(@uncompressed));

        say("\nEst. ratio: ", $est_ratio, " (", scalar(@uncompressed), " uncompressed bytes)");

        if ($est_ratio > 0.8) {
            print $out_fh COMPRESSED_BYTE;
            print $out_fh pack('N', $idx);
            print $out_fh encode_alphabet(\@alphabet);
            create_huffman_entry(\@uncompressed, $out_fh);
            create_huffman_entry(\@lengths,      $out_fh);
            encode_distances(\@indices, $out_fh);
        }
        else {
            print $out_fh UNCOMPRESSED_BYTE;
            create_huffman_entry(\@chunk_bytes, $out_fh);
        }
    }

    # Close the output file
    close $out_fh;
}

# Decompress file
sub lz77h_decompress_file ($input, $output) {

    # Open and validate the input file
    open my $fh, '<:raw', $input;
    valid_archive($fh) || die "$0: file `$input' is not a \U${\FORMAT}\E v${\VERSION} archive!\n";

    # Open the output file
    open my $out_fh, '>:raw', $output;

    while (!eof($fh)) {

        my $compression_byte = getc($fh);

        if ($compression_byte eq COMPRESSED_BYTE) {

            my $idx          = unpack('N', join('', map { getc($fh) // die "error" } 1 .. 4));
            my $alphabet     = decode_alphabet($fh);
            my @uncompressed = split(//, decode_huffman_entry($fh));
            my @lengths      = unpack('C*', decode_huffman_entry($fh));
            my $indices      = decode_distances($fh);

            my $dec   = lz77_decompression(\@uncompressed, $indices, \@lengths);
            my $bytes = [unpack('C*', $dec)];

            if ($alphabet->[-1] < 255) {
                $bytes = rle_decode($bytes);
            }

            $bytes = mtf_decode($bytes, [@$alphabet]);

            print $out_fh pack('C*', @{rle4_decode([unpack('C*', bwt_decode(pack('C*', @$bytes), $idx))])});
        }
        elsif ($compression_byte eq UNCOMPRESSED_BYTE) {
            print $out_fh decode_huffman_entry($fh);
        }
        else {
            die "Invalid compression...";
        }
    }

    # Close the output file
    close $out_fh;
}

main();
exit(0);
