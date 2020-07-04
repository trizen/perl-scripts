#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Derived: 13 July 2016
# Coded: 23 October 2016
# Website: https://github.com/trizen

# A derivation of the Ethiopian multiplication method (also known as "Russian multiplication").

# a*b = sum((floor(a * 2^(-k)) mod 2) * b*2^k, {k = 0, floor(log(a)/log(2))})

# See also:
#   http://mathworld.wolfram.com/RussianMultiplication.html

use 5.010;
use strict;
use warnings;

use ntheory qw(hammingweight todigitstring);

sub ethiopian_multiplication {
    my ($x, $y) = @_;

    # We can swap "x" with "y" if "y" has a lower Hamming-weight value than "x".
    # This optimization reduces considerably the number of required additions.

    my $h1 = hammingweight($x);
    my $h2 = hammingweight($y);

    if ($h2 < $h1) {
        ($x, $y) = ($y, $x);
    }

    my @r;
    while ($x > 0) {

        if ($x & 1) {
            push @r, '0b' . todigitstring($y, 2);
        }

        $y <<= 1;
        $x >>= 1;
    }

    return join('+', @r);
}

say ethiopian_multiplication(3,  5);    #=>                  0b101+0b1010
say ethiopian_multiplication(63, 7);    #=> 0b111111+0b1111110+0b11111100
