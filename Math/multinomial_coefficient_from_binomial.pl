#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 04 February 2018
# https://github.com/trizen

# Identity for computing the multinomial coefficient using binomial coefficients.

# See also:
#   http://mathworld.wolfram.com/MultinomialCoefficient.html
#   https://en.wikipedia.org/wiki/Multinomial_theorem

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(:overload binomial);

sub multinomial (@mset) {

    my $prod = 1;
    my $n    = shift(@mset);

    foreach my $k (@mset) {
        $prod *= binomial($n += $k, $k);
    }

    return $prod;
}

say multinomial(7, 2, 5, 2, 12, 11);    # 440981754363423854380800
