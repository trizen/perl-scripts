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

use ntheory qw(:all);
use Math::AnyNum qw(:overload prod);

sub cyclotomic_polynomial {
    my ($n, $x) = @_;

    # Special case for x = 1: cyclotomic(n, 1) is A020500.
    if ($x == 1) {
        my $k = is_prime_power($n) || return 1;
        my $p = rootint($n, $k);
        return $p;
    }

    # Special case for x = -1: cyclotomic(n, -1) is A020513.
    if ($x == -1) {
        ($n % 2 == 0) || return 1;
        my $k = is_prime_power($n >> 1) || return 1;
        my $p = rootint($n >> 1, $k);
        return $p;
    }

    # Generate the squarefree divisors of n, along
    # with the number of prime factors of each divisor
    my @d;
    foreach my $p (map { $_->[0] } factor_exp($n)) {
        push @d, map { [$_->[0] * $p, $_->[1] + 1] } @d;
        push @d, [$p, 1];
    }

    push @d, [1, 0];

    # Multiply the terms
    prod(map { ($x**($n / $_->[0]) - 1)**((-1)**$_->[1]) } @d);
}

say cyclotomic_polynomial(5040, 4 / 3);
say join(', ', map { cyclotomic_polynomial($_, 2) } 1 .. 20);    # https://oeis.org/A019320
