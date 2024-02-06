#!/usr/bin/perl

# Author: Trizen
# Date: 12 July 2023
# Edit: 05 February 2024
# https://github.com/trizen

# The Arithmetic Coding algorithm, implemented using native integers.

# References:
#   Data Compression (Summer 2023) - Lecture 15 - Infinite Precision in Finite Bits
#   https://youtube.com/watch?v=EqKbT3QdtOI
#
#   Basic arithmetic coder in C++
#   https://github.com/billbird/arith32

use 5.036;

use List::Util qw(max);

use constant BITS => 32;
use constant MAX  => oct('0b' . ('1' x BITS));

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

sub encode ($string) {

    my $enc   = '';
    my @bytes = unpack('C*', $string);

    my $EOF_SYMBOL = (max(@bytes) // 0) + 1;
    push @bytes, $EOF_SYMBOL;

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

sub decode ($bits, $freq) {
    open my $fh, '<:raw', \$bits;

    my ($cf_low, $cf_high, $T) = create_cfreq($freq);

    my $dec  = '';
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

        $dec .= chr($i);

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

my ($enc, $freq) = encode($str);

say $enc;
say "Encoded bytes length: ", length($enc) / 8;

my $dec = decode($enc, $freq);
say $dec;
$str eq $dec or die "Decoding error: ", length($str), ' <=> ', length($dec);

__END__
0100110110111110100000000100000111110000110110011111000010110011011001000101100011011101001110000000010001111111
Encoded bytes length: 14
ABRACADABRA AND A VERY SAD SALAD
