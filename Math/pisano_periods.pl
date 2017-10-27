#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 11 October 2017
# https://github.com/trizen

# Algorithm for computing the Pisano numbers (period of Fibonacci numbers mod n), using the prime factorization of `n`.

# See also:
#   https://oeis.org/A001175
#   https://en.wikipedia.org/wiki/Pisano_period

use 5.020;
use strict;
use warnings;

use experimental qw(signatures lexical_subs);
use ntheory qw(addmod factor_exp lcm);

sub pisano_period($mod) {

    my sub find_period($mod) {
        my ($x, $y) = (0, 1);

        for (my $n = 1 ; ; ++$n) {
            ($x, $y) = ($y, addmod($x, $y, $mod));

            if ($x == 0 and $y == 1) {
                return $n;
            }
        }
    }

    my @prime_powers  = map { $_->[0]**$_->[1] } factor_exp($mod);
    my @power_periods = map { find_period($_) } @prime_powers;

    return lcm(@power_periods);
}

my $n      = 5040;
my $period = pisano_period($n);
say "Pisano period for modulus $n is $period.";    #=> 240
