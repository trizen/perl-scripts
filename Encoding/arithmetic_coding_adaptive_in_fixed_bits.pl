#!/usr/bin/perl

# Author: Trizen
# Date: 12 July 2023
# Edit: 05 February 2024
# https://github.com/trizen

# The Arithmetic Coding algorithm (adaptive version), implemented using native integers.

# References:
#   Data Compression (Summer 2023) - Lecture 15 - Infinite Precision in Finite Bits
#   https://youtube.com/watch?v=EqKbT3QdtOI
#
#   Data Compression (Summer 2023) - Lecture 16 - Adaptive Methods
#   https://youtube.com/watch?v=YKv-w8bXi9c
#
#   Basic arithmetic coder in C++
#   https://github.com/billbird/arith32

use 5.036;

use List::Util qw(max);

use constant EOF_SYMBOL => 256;
use constant BITS       => 32;
use constant MAX        => oct('0b' . ('1' x BITS));

sub create_cfreq ($freq_value) {

    my $T = 0;
    my (@cf, @freq);

    foreach my $i (0 .. EOF_SYMBOL) {
        $freq[$i] = $freq_value;
        $cf[$i]   = $T;
        $T += $freq_value;
        $cf[$i + 1] = $T;
    }

    return (\@freq, \@cf, $T);
}

sub increment_freq ($c, $freq, $cf) {

    ++$freq->[$c];
    my $T = $cf->[$c];

    foreach my $i ($c .. EOF_SYMBOL) {
        $cf->[$i] = $T;
        $T += $freq->[$i];
        $cf->[$i + 1] = $T;
    }

    return $T;
}

sub encode ($string) {

    my $enc   = '';
    my $bytes = [unpack('C*', $string), EOF_SYMBOL];

    my ($freq, $cf, $T) = create_cfreq(1);

    if ($T > MAX) {
        die "Too few bits: $T > ${\MAX}";
    }

    my $low      = 0;
    my $high     = MAX;
    my $uf_count = 0;

    foreach my $c (@$bytes) {

        my $w = $high - $low + 1;

        $high = ($low + int(($w * $cf->[$c + 1]) / $T) - 1) & MAX;
        $low  = ($low + int(($w * $cf->[$c]) / $T)) & MAX;

        $T = increment_freq($c, $freq, $cf);

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

    return $enc;
}

sub decode ($bits) {
    open my $fh, '<:raw', \$bits;

    my ($freq, $cf, $T) = create_cfreq(1);

    my $dec  = '';
    my $low  = 0;
    my $high = MAX;
    my $enc  = oct('0b' . join '', map { getc($fh) // 1 } 1 .. BITS);

    while (1) {

        my $w  = $high - $low + 1;
        my $ss = int((($T * ($enc - $low + 1)) - 1) / $w);

        my $i = 0;
        foreach my $j (0 .. EOF_SYMBOL) {
            if ($cf->[$j] <= $ss and $ss < $cf->[$j + 1]) {
                $i = $j;
                last;
            }
        }

        last if ($i == EOF_SYMBOL);

        $dec .= chr($i);

        $high = ($low + int(($w * $cf->[$i + 1]) / $T) - 1) & MAX;
        $low  = ($low + int(($w * $cf->[$i]) / $T)) & MAX;

        $T = increment_freq($i, $freq, $cf);

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

    return $dec;
}

my $str = "ABRACADABRA AND A VERY SAD SALAD";

if (@ARGV) {
    if (-f $ARGV[0]) {
        $str = do {
            open my $fh, '<:raw', $ARGV[0];
            local $/;
            <$fh>;
        };
    }
    else {
        $str = $ARGV[0];
    }
}

my ($enc) = encode($str);

say $enc;
say "Encoded bytes length: ", length($enc) / 8;

my $dec = decode($enc);
say $dec;
$str eq $dec or die "Decoding error: ", length($str), ' <=> ', length($dec);

__END__
0100000100000001110010111101111100111011001101010100000111010101101011111111010100110100011111001010110010110110010001001100100111000101010111111101011110101001010110111111000111101000010110011000010100100111110010011111110111011111
Encoded bytes length: 29
ABRACADABRA AND A VERY SAD SALAD
