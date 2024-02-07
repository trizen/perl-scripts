#!/usr/bin/perl

# Author: Trizen
# Date: 14 June 2023
# Edit: 06 February 2024
# https://github.com/trizen

# Compress/decompress files using Burrows-Wheeler Transform (BWT) + Move-to-Front Transform + Run-length encoding + Adaptive Arithmetic Coding.

# Reference:
#   Data Compression (Summer 2023) - Lecture 13 - BZip2
#   https://youtube.com/watch?v=cvoZbBZ3M2A

use 5.036;

use Getopt::Std    qw(getopts);
use File::Basename qw(basename);
use List::Util     qw(max uniq);

use constant {
    PKGNAME => 'BWAD',
    VERSION => '0.02',
    FORMAT  => 'bwad',

    CHUNK_SIZE    => 1 << 16,
    LOOKAHEAD_LEN => 128,
};

# Arithmetic Coding settings
use constant BITS         => 32;
use constant MAX          => oct('0b' . ('1' x BITS));
use constant INITIAL_FREQ => 1;

# Container signature
use constant SIGNATURE => uc(FORMAT) . chr(2);

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

sub create_cfreq ($freq_value, $max_symbol) {

    my $T = 0;
    my (@cf, @freq);

    foreach my $i (0 .. $max_symbol) {
        $freq[$i] = $freq_value;
        $cf[$i]   = $T;
        $T += $freq_value;
        $cf[$i + 1] = $T;
    }

    return (\@freq, \@cf, $T);
}

sub increment_freq ($c, $max_symbol, $freq, $cf) {

    ++$freq->[$c];
    my $T = $cf->[$c];

    foreach my $i ($c .. $max_symbol) {
        $cf->[$i] = $T;
        $T += $freq->[$i];
        $cf->[$i + 1] = $T;
    }

    return $T;
}

sub ac_encode ($bytes_arr) {

    my $enc   = '';
    my @bytes = (@$bytes_arr, (max(@$bytes_arr) // 0) + 1);

    my $max_symbol = max(@bytes) // 0;
    my ($freq, $cf, $T) = create_cfreq(INITIAL_FREQ, $max_symbol);

    if ($T > MAX) {
        die "Too few bits: $T > ${\MAX}";
    }

    my $low      = 0;
    my $high     = MAX;
    my $uf_count = 0;

    foreach my $c (@bytes) {

        my $w = $high - $low + 1;

        $high = ($low + int(($w * $cf->[$c + 1]) / $T) - 1) & MAX;
        $low  = ($low + int(($w * $cf->[$c]) / $T)) & MAX;

        $T = increment_freq($c, $max_symbol, $freq, $cf);

        if ($high > MAX) {
            die "high > MAX: $high > ${\MAX}";
        }

        if ($low >= $high) { die "$low >= $high" }

        while (1) {

            if (($high >> (BITS - 1)) == ($low >> (BITS - 1))) {

                my $bit = $high >> (BITS - 1);
                $enc .= $bit;

                if ($uf_count > 0) {
                    $enc .= join('', 1 - $bit) x $uf_count;
                    $uf_count = 0;
                }

                $low <<= 1;
                ($high <<= 1) |= 1;
            }
            elsif (((($low >> (BITS - 2)) & 0x1) == 1) && ((($high >> (BITS - 2)) & 0x1) == 0)) {
                ($high <<= 1) |= (1 << (BITS - 1));
                $high |= 1;
                ($low <<= 1) &= ((1 << (BITS - 1)) - 1);
                ++$uf_count;
            }
            else {
                last;
            }

            $low  &= MAX;
            $high &= MAX;
        }
    }

    $enc .= '0';
    $enc .= '1';

    while (length($enc) % 8 != 0) {
        $enc .= '1';
    }

    return ($enc, $max_symbol);
}

sub ac_decode ($fh, $max_symbol) {

    my ($freq, $cf, $T) = create_cfreq(INITIAL_FREQ, $max_symbol);

    my @dec;
    my $low  = 0;
    my $high = MAX;

    my $enc = oct('0b' . join '', map { getc($fh) // 1 } 1 .. BITS);

    while (1) {
        my $w  = ($high + 1) - $low;
        my $ss = int((($T * ($enc - $low + 1)) - 1) / $w);

        my $i = 0;
        foreach my $j (0 .. $max_symbol) {
            if ($cf->[$j] <= $ss and $ss < $cf->[$j + 1]) {
                $i = $j;
                last;
            }
        }

        last if ($i == $max_symbol);
        push @dec, $i;

        $high = ($low + int(($w * $cf->[$i + 1]) / $T) - 1) & MAX;
        $low  = ($low + int(($w * $cf->[$i]) / $T)) & MAX;

        $T = increment_freq($i, $max_symbol, $freq, $cf);

        if ($high > MAX) {
            die "high > MAX: ($high > ${\MAX})";
        }

        if ($low >= $high) { die "$low >= $high" }

        while (1) {

            if (($high >> (BITS - 1)) == ($low >> (BITS - 1))) {
                ($high <<= 1) |= 1;
                $low <<= 1;
                ($enc <<= 1) |= (getc($fh) // 1);
            }
            elsif (((($low >> (BITS - 2)) & 0x1) == 1) && ((($high >> (BITS - 2)) & 0x1) == 0)) {
                ($high <<= 1) |= (1 << (BITS - 1));
                $high |= 1;
                ($low <<= 1) &= ((1 << (BITS - 1)) - 1);
                $enc = (($enc >> (BITS - 1)) << (BITS - 1)) | (($enc & ((1 << (BITS - 2)) - 1)) << 1) | (getc($fh) // 1);
            }
            else {
                last;
            }

            $low  &= MAX;
            $high &= MAX;
            $enc  &= MAX;
        }
    }

    return \@dec;
}

sub create_ac_entry ($bytes, $out_fh) {

    my ($enc, $max_symbol) = ac_encode($bytes);

    say "Max symbol: $max_symbol\n";

    print $out_fh delta_encode([$max_symbol, length($enc)], 1);
    print $out_fh pack("B*", $enc);
}

sub decode_ac_entry ($fh) {

    my ($max_symbol, $enc_len) = @{delta_decode($fh, 1)};

    say "Encoded length: $enc_len\n";

    if ($enc_len > 0) {
        my $bits = read_bits($fh, $enc_len);
        open my $bits_fh, '<:raw', \$bits;
        return ac_decode($bits_fh, $max_symbol);
    }

    return [];
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
    create_ac_entry($rle, $out_fh);
}

sub decompression ($fh, $out_fh) {

    my $idx      = unpack('N', join('', map { getc($fh) // return undef } 1 .. 4));
    my $alphabet = decode_alphabet($fh);

    say "BWT index = $idx";
    say "Alphabet size: ", scalar(@$alphabet);

    my $rle  = decode_ac_entry($fh);
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
