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

sub ethiopian_multiplication {
    my ($x, $y) = @_;

    my $r = 0;
    foreach my $k (0 .. log($x) / log(2)) {
        $r += (($x >> $k) % 2) * ($y << $k);
    }
    return $r;
}

say ethiopian_multiplication(3,  5);    #=>  15
say ethiopian_multiplication(7, 41);    #=> 287
