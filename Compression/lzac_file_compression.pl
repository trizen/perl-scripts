#!/usr/bin/perl

# Author: Trizen
# Date: 15 December 2022
# Edit: 06 February 2024
# https://github.com/trizen

# Compress/decompress files using LZ77 compression + Arithmetic Coding (in fixed bits).

# Encoding the distances/indices using a DEFLATE-like approach.

# References:
#   Data Compression (Summer 2023) - Lecture 11 - DEFLATE (gzip)
#   https://youtube.com/watch?v=SJPvNi4HrWQ
#
#   Basic arithmetic coder in C++
#   https://github.com/billbird/arith32

use 5.036;

use Getopt::Std    qw(getopts);
use File::Basename qw(basename);
use List::Util     qw(max sum);

use constant {
    PKGNAME => 'LZAC',
    VERSION => '0.02',
    FORMAT  => 'lzac',

    COMPRESSED_BYTE   => chr(1),
    UNCOMPRESSED_BYTE => chr(0),
    CHUNK_SIZE        => 1 << 16,    # higher value = better compression
};

# Arithmetic Coding settings
use constant BITS => 32;
use constant MAX  => oct('0b' . ('1' x BITS));

# Container signature
use constant SIGNATURE => uc(FORMAT) . chr(2);

# [distance value, offset bits]
my @DISTANCE_SYMBOLS = map { [$_, 0] } (0 .. 4);

until ($DISTANCE_SYMBOLS[-1][0] > CHUNK_SIZE) {
    push @DISTANCE_SYMBOLS, [int($DISTANCE_SYMBOLS[-1][0] * (4 / 3)), $DISTANCE_SYMBOLS[-1][1] + 1];
    push @DISTANCE_SYMBOLS, [int($DISTANCE_SYMBOLS[-1][0] * (3 / 2)), $DISTANCE_SYMBOLS[-1][1]];
}

my @DISTANCE_INDICES;

foreach my $i (0 .. $#DISTANCE_SYMBOLS) {
    my ($min, $bits) = @{$DISTANCE_SYMBOLS[$i]};
    foreach my $k ($min .. $min + (1 << $bits) - 1) {
        last if ($k > CHUNK_SIZE);
        $DISTANCE_INDICES[$k] = $i;
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

sub lz77_compression ($str, $uncompressed, $indices, $lengths) {

    my $la = 0;

    my $prefix = '';
    my @chars  = split(//, $str);
    my $end    = $#chars;

    while ($la <= $end) {

        my $n = 1;
        my $p = length($prefix);
        my $tmp;

        my $token = $chars[$la];

        while (    $n < 255
               and $la + $n <= $end
               and ($tmp = rindex($prefix, $token, $p)) >= 0) {
            $p = $tmp;
            $token .= $chars[$la + $n];
            ++$n;
        }

        --$n;
        push @$indices,      $la - $p;
        push @$lengths,      $n;
        push @$uncompressed, ord($chars[$la + $n]);
        $la += $n + 1;
        $prefix .= $token;
    }

    return;
}

sub lz77_decompression ($uncompressed, $indices, $lengths) {

    my $chunk  = '';
    my $offset = 0;

    foreach my $i (0 .. $#{$uncompressed}) {
        $chunk .= substr($chunk, $offset - $indices->[$i], $lengths->[$i]) . chr($uncompressed->[$i]);
        $offset += $lengths->[$i] + 1;
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

sub create_cfreq ($freq) {

    my %cf_low;
    my %cf_high;
    my $T = 0;

    foreach my $i (sort { $a <=> $b } keys %$freq) {
        $freq->{$i} // next;
        $cf_low{$i} = $T;
        $T += $freq->{$i};
        $cf_high{$i} = $T;
    }

    return (\%cf_low, \%cf_high, $T);
}

sub ac_encode ($bytes_arr) {

    my $enc        = '';
    my $EOF_SYMBOL = (max(@$bytes_arr) // 0) + 1;
    my @bytes      = (@$bytes_arr, $EOF_SYMBOL);

    my %freq;
    ++$freq{$_} for @bytes;

    my ($cf_low, $cf_high, $T) = create_cfreq(\%freq);

    if ($T > MAX) {
        die "Too few bits: $T > ${\MAX}";
    }

    my $low      = 0;
    my $high     = MAX;
    my $uf_count = 0;

    foreach my $c (@bytes) {

        my $w = $high - $low + 1;

        $high = ($low + int(($w * $cf_high->{$c}) / $T) - 1) & MAX;
        $low  = ($low + int(($w * $cf_low->{$c}) / $T)) & MAX;

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

    return ($enc, \%freq);
}

sub ac_decode ($fh, $freq) {

    my ($cf_low, $cf_high, $T) = create_cfreq($freq);

    my @dec;
    my $low  = 0;
    my $high = MAX;
    my $enc  = oct('0b' . join '', map { getc($fh) // 1 } 1 .. BITS);

    my @table;
    foreach my $i (sort { $a <=> $b } keys %$freq) {
        foreach my $j ($cf_low->{$i} .. $cf_high->{$i} - 1) {
            $table[$j] = $i;
        }
    }

    my $EOF_SYMBOL = max(keys %$freq) // 0;

    while (1) {

        my $w  = $high - $low + 1;
        my $ss = int((($T * ($enc - $low + 1)) - 1) / $w);

        my $i = $table[$ss] // last;
        last if ($i == $EOF_SYMBOL);

        push @dec, $i;

        $high = ($low + int(($w * $cf_high->{$i}) / $T) - 1) & MAX;
        $low  = ($low + int(($w * $cf_low->{$i}) / $T)) & MAX;

        if ($high > MAX) {
            die "error";
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

    my ($enc, $freq) = ac_encode($bytes);
    my $max_symbol = max(keys %$freq) // 0;

    my @freqs;
    foreach my $k (0 .. $max_symbol) {
        push @freqs, $freq->{$k} // 0;
    }

    push @freqs, length($enc) >> 3;

    print $out_fh delta_encode(\@freqs);
    print $out_fh pack("B*", $enc);
}

sub decode_ac_entry ($fh) {

    my @freqs    = @{delta_decode($fh)};
    my $bits_len = pop(@freqs);

    my %freq;
    foreach my $i (0 .. $#freqs) {
        if ($freqs[$i]) {
            $freq{$i} = $freqs[$i];
        }
    }

    say "Encoded length: $bits_len";
    my $bits = read_bits($fh, $bits_len << 3);

    if ($bits_len > 0) {
        open my $bits_fh, '<:raw', \$bits;
        return ac_decode($bits_fh, \%freq);
    }

    return [];
}

sub encode_distances ($distances, $out_fh) {

    my @symbols;
    my $offset_bits = '';

    foreach my $dist (@$distances) {

        my $i = $DISTANCE_INDICES[$dist];
        my ($min, $bits) = @{$DISTANCE_SYMBOLS[$i]};

        push @symbols, $i;

        if ($bits > 0) {
            $offset_bits .= sprintf('%0*b', $bits, $dist - $min);
        }
    }

    create_ac_entry(\@symbols, $out_fh);
    print $out_fh pack('B*', $offset_bits);
}

sub decode_distances ($fh) {

    my $symbols  = decode_ac_entry($fh);
    my $bits_len = 0;

    foreach my $i (@$symbols) {
        $bits_len += $DISTANCE_SYMBOLS[$i][1];
    }

    my $bits = read_bits($fh, $bits_len);

    my @distances;
    foreach my $i (@$symbols) {
        push @distances, $DISTANCE_SYMBOLS[$i][0] + oct('0b' . substr($bits, 0, $DISTANCE_SYMBOLS[$i][1], ''));
    }

    return \@distances;
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

        my (@uncompressed, @indices, @lengths);
        lz77_compression($chunk, \@uncompressed, \@indices, \@lengths);

        my $est_ratio = length($chunk) / (4 * scalar(@uncompressed));

        say(scalar(@uncompressed), ' -> ', $est_ratio);

        if ($est_ratio > 0.85) {
            print $out_fh COMPRESSED_BYTE;
            create_ac_entry(\@uncompressed, $out_fh);
            create_ac_entry(\@lengths,      $out_fh);
            encode_distances(\@indices, $out_fh);
        }
        else {
            print $out_fh UNCOMPRESSED_BYTE;
            create_ac_entry([unpack('C*', $chunk)], $out_fh);
        }
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

        my $compression_byte = getc($fh);

        if ($compression_byte eq COMPRESSED_BYTE) {

            my $uncompressed = decode_ac_entry($fh);
            my $lengths      = decode_ac_entry($fh);
            my $indices      = decode_distances($fh);

            print $out_fh lz77_decompression($uncompressed, $indices, $lengths);
        }
        elsif ($compression_byte eq UNCOMPRESSED_BYTE) {
            print $out_fh pack('C*', @{decode_ac_entry($fh)});
        }
        else {
            die "Invalid compression...";
        }
    }

    # Close the file
    close $fh;
    close $out_fh;
}

main();
exit(0);
