#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 01 February 2018
# https://github.com/trizen

# Simple algorithm for computing the multinomial coefficient, using prime powers.

# See also:
#   http://mathworld.wolfram.com/MultinomialCoefficient.html

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(forprimes vecsum);
use Math::AnyNum qw(:overload digits);

sub factorial_power ($n, $p) {
    ($n - vecsum(digits($n, $p))) / ($p - 1);
}

sub multinomial (@mset) {

    my $sum  = vecsum(@mset);
    my $prod = 1;
    my $end  = $#mset;

    forprimes {
        my $p = $_;
        my $e = factorial_power($sum, $p);

        for (my $i = $end ; $i >= 0 ; --$i) {

            my $n = $mset[$i];

            if ($p <= $n) {
                $e -= factorial_power($n, $p);
            }
            else {
                splice(@mset, $i, 1), --$end;
            }
        }

        $prod *= $p**$e;
    } $sum;

    return $prod;
}

say multinomial(7, 2, 5, 2, 12, 11);    # 440981754363423854380800
