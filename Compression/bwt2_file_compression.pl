#!/usr/bin/perl

# Author: Trizen
# Date: 14 June 2023
# Edit: 19 March 2024
# https://github.com/trizen

# Compress/decompress files using Burrows-Wheeler Transform (BWT) + Move-To-Front transform (MTF) + Run-length encoding (RLE) + Bzip2.

# Reference:
#   Data Compression (Summer 2023) - Lecture 13 - BZip2
#   https://youtube.com/watch?v=cvoZbBZ3M2A

use 5.036;

use Getopt::Std    qw(getopts);
use File::Basename qw(basename);
use List::Util     qw(max uniq);

use constant {
    PKGNAME => 'BWT2',
    VERSION => '0.01',
    FORMAT  => 'bwt2',

    CHUNK_SIZE    => 1 << 17,
    LOOKAHEAD_LEN => 128,
};

# Container signature
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

# produce encode and decode dictionary from a tree
sub walk ($node, $code, $h, $rev_h) {

    my $c = $node->[0] // return ($h, $rev_h);
    if (ref $c) { walk($c->[$_], $code . $_, $h, $rev_h) for (0, 1) }
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
    say "Max symbol: $max_symbol\n";

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
    say "Encoded length: $enc_len\n";

    if ($enc_len > 0) {
        return huffman_decode(read_bits($fh, $enc_len), $rev_dict);
    }

    return [];
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

sub bwt_balanced ($s) {    # O(n * LOOKAHEAD_LEN) space (fast)
#<<<
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
#>>>
}

sub bwt_encode ($s) {

    my $bwt = bwt_balanced($s);
    my $ret = join('', map { substr($s, $_ - 1, 1) } @$bwt);

    my $idx = 0;
    foreach my $i (@$bwt) {
        $i || last;
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

            while ($run < 255 and $i <= $end and $bytes->[$i] == $prev) {
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

    my @populated = split(//, sprintf('%08b', ord(getc($fh))));
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

sub bwt_sort_symbolic ($s) {    # O(n) space (slowish)

    my @cyclic = @$s;
    my $len    = scalar(@cyclic);

    my $rle = 1;
    foreach my $i (1 .. $len - 1) {
        if ($cyclic[$i] != $cyclic[$i - 1]) {
            $rle = 0;
            last;
        }
    }

    $rle && return [0 .. $len - 1];

    [
     sort {
         my ($i, $j) = ($a, $b);

         while ($cyclic[$i] == $cyclic[$j]) {
             $i %= $len if (++$i >= $len);
             $j %= $len if (++$j >= $len);
         }

         $cyclic[$i] <=> $cyclic[$j];
       } 0 .. $len - 1
    ];
}

sub bwt_encode_symbolic ($s) {

    my $bwt = bwt_sort_symbolic($s);
    my @ret = map { $s->[$_ - 1] } @$bwt;

    my $idx = 0;
    foreach my $i (@$bwt) {
        $i || last;
        ++$idx;
    }

    return (\@ret, $idx);
}

sub bwt_decode_symbolic ($bwt, $idx) {    # fast inversion

    my @tail = @$bwt;
    my @head = sort { $a <=> $b } @tail;

    my @indices;
    foreach my $i (0 .. $#tail) {
        push @{$indices[$tail[$i]]}, $i;
    }

    my @table;
    foreach my $v (@head) {
        push @table, shift(@{$indices[$v]});
    }

    my @dec;
    my $i = $idx;

    for (1 .. scalar(@head)) {
        push @dec, $head[$i];
        $i = $table[$i];
    }

    return \@dec;
}

sub encode_alphabet_symbolic ($alphabet) {
    return delta_encode([@$alphabet]);
}

sub decode_alphabet_symbolic ($fh) {
    return [@{delta_decode($fh)}];
}

sub bz2_compression_symbolic ($symbols, $out_fh) {

    my $rle4 = rle4_encode($symbols);
    my ($bwt, $idx) = bwt_encode_symbolic($rle4);

    my @bytes        = @$bwt;
    my @alphabet     = sort { $a <=> $b } uniq(@bytes);
    my $alphabet_enc = encode_alphabet_symbolic(\@alphabet);

    say "BWT index = $idx";
    say "Max symbol: ", max(@alphabet) // 0;

    my $mtf = mtf_encode(\@bytes, [@alphabet]);
    my $rle = rle_encode($mtf);

    print $out_fh pack('N', $idx);
    print $out_fh $alphabet_enc;
    create_huffman_entry($rle, $out_fh);
}

sub bz2_decompression_symbolic ($fh) {

    my $idx      = unpack('N', join('', map { getc($fh) // die "error" } 1 .. 4));
    my $alphabet = decode_alphabet_symbolic($fh);

    say "BWT index = $idx";
    say "Alphabet size: ", scalar(@$alphabet);

    my $rle  = decode_huffman_entry($fh);
    my $mtf  = rle_decode($rle);
    my $bwt  = mtf_decode($mtf, $alphabet);
    my $data = bwt_decode_symbolic($bwt, $idx);

    return rle4_decode($data);
}

sub compression ($chunk, $out_fh) {

    my $rle4 = rle4_encode([unpack('C*', $chunk)]);
    my ($bwt, $idx) = bwt_encode(pack('C*', @$rle4));

    say "BWT index = $idx";

    my @bytes        = unpack('C*', $bwt);
    my @alphabet     = sort { $a <=> $b } uniq(@bytes);
    my $alphabet_enc = encode_alphabet(\@alphabet);

    my $mtf = mtf_encode(\@bytes, [@alphabet]);
    my $rle = rle_encode($mtf);

    print $out_fh pack('N', $idx);
    print $out_fh $alphabet_enc;

    my @alphabet2 = sort { $a <=> $b } uniq(@$rle);
    my $mtf2      = mtf_encode([@$rle], [@alphabet2]);
    my $rle2      = rle4_encode($mtf2);

    my @alphabet3 = sort { $a <=> $b } uniq(@$rle2);
    my $mtf3      = mtf_encode([@$rle2], [@alphabet3]);

    print $out_fh encode_alphabet_symbolic(\@alphabet2);
    print $out_fh encode_alphabet_symbolic(\@alphabet3);

    bz2_compression_symbolic($mtf3, $out_fh);
}

sub decompression ($fh, $out_fh) {

    my $idx       = unpack('N', join('', map { getc($fh) // return undef } 1 .. 4));
    my $alphabet  = decode_alphabet($fh);
    my $alphabet2 = decode_alphabet_symbolic($fh);
    my $alphabet3 = decode_alphabet_symbolic($fh);

    say "BWT index = $idx";
    say "Alphabet size: ", scalar(@$alphabet);

    my $mtf3 = bz2_decompression_symbolic($fh);
    my $rle2 = mtf_decode($mtf3, $alphabet3);
    my $mtf2 = rle4_decode($rle2);
    my $rle  = mtf_decode($mtf2, $alphabet2);
    my $mtf  = rle_decode($rle);
    my $bwt  = mtf_decode($mtf, $alphabet);
    my $rle4 = bwt_decode(pack('C*', @$bwt), $idx);
    my $data = rle4_decode([unpack('C*', $rle4)]);

    print $out_fh pack('C*', @$data);
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
