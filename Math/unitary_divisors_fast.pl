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

use ntheory qw(factor_exp);

sub udivisors {
    my ($n) = @_;

    my @d  = (1);
    my @pp = map { $_->[0]**$_->[1] } factor_exp($n);

    foreach my $p (@pp) {
        push @d, map { $_ * $p } @d;
    }

    return sort { $a <=> $b } @d;
}

say join(' ', udivisors(5040));
