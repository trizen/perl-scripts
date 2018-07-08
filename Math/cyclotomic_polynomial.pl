#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 08 July 2018
# https://github.com/trizen

# Efficient formula for computing the n-th cyclotomic polynomial.

# Formula:
#   cyclotomic(n, x) = Prod_{d|n} (x^(n/d) - 1)^moebius(d)

# Optimization: by generating only the squarefree divisors of n and keeping track of
# the number of prime factors of each divisor, we do not need the Moebius function.

# See also:
#   https://en.wikipedia.org/wiki/Cyclotomic_polynomial

use 5.010;
use strict;
use warnings;

use ntheory qw(factor_exp);
use Math::AnyNum qw(:overload prod);

sub cyclotomic_polynomial {
    my ($n, $x) = @_;

    my @d;
    my @pp = map { $_->[0] } factor_exp($n);

    # Generate the squarefree divisors of n, along
    # with the number of prime factors of each divisor
    foreach my $p (@pp) {
        push @d, map { [$d[$_][0] * $p, $d[$_][1] + 1] } 0 .. $#d;
        push @d, [$p, 1];
    }

    push @d, [1, 0];

    # Multiply the terms
    prod(map { ($x**($n / $_->[0]) - 1)**((-1)**$_->[1]) } @d);
}

say cyclotomic_polynomial(5040, 4/3);
say join(', ', map { cyclotomic_polynomial($_, 2) } 1 .. 20);    # https://oeis.org/A019320
