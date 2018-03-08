#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 08 March 2018
# https://github.com/trizen

# Given an integer `n`, find the smallest integer k>=3 such that `n` is a k-gonal number.

# Example:
#  a(12) = 5 since 12 is a pentagonal number, but not a square or triangular.

# See also:
#   https://oeis.org/A176774

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use ntheory qw(divisors);
use Math::AnyNum qw(:overload polygonal);

sub smallest_k_gonal_inverse ($n) {

    my @divisors = divisors(2 * $n);

    shift @divisors;
    pop @divisors;

    foreach my $d (reverse(@divisors)) {

        my $t = $d - 1;
        my $k = 2*$n / $d + 2*$d - 4;

        if ($k % $t == 0) {
            my $z = $k / $t;

            if ($z > 2 && $z < $n) {
                return $k / $t;
            }
        }
    }

    return $n;
}

foreach my $n (4000 .. 4030) {
    say "a($n) = ", smallest_k_gonal_inverse($n);
}
