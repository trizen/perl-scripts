#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 01 July 2018
# https://github.com/trizen

# A simple algorithm for generating the unitary divisors of a given number.

# See also:
#   https://en.wikipedia.org/wiki/Unitary_divisor

use 5.010;
use strict;
use warnings;

use ntheory qw(forcomb factor_exp vecprod powint);

# This algorithm nicely illustrates the identity:
#
#   2^n = Sum_{k=0..n} binomial(n, k)
#
# which is the number of divisors of a squarefree number that is the product of `n` primes.

sub udivisors {
    my ($n) = @_;

    my @pp  = map { powint($_->[0], $_->[1]) } factor_exp($n);
    my $len = scalar(@pp);

    my @d;
    foreach my $k (0 .. $len) {
        forcomb {
            push @d, vecprod(@pp[@_]);
        } $len, $k;
    }

    return sort { $a <=> $b } @d;
}

say join(' ', udivisors(5040));
