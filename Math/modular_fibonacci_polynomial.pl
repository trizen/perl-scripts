#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 11 October 2017
# https://github.com/trizen

# Algorithm for computing a Fibonacci polynomial modulo m.

#   (Sum_{k=1..n} (fibonacci(k) * x^k)) (mod m)

# See also:
#   https://projecteuler.net/problem=435

use 5.020;
use strict;
use warnings;

use experimental qw(signatures lexical_subs);
use ntheory qw(lcm addmod mulmod factor_exp powmod);

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

sub modular_fibonacci_polynomial ($n, $x, $mod) {

    $n %= pisano_period($mod);

    my $sum = 0;

    my ($f1, $f2) = (0, 1);
    foreach my $k (1 .. $n) {
        $sum = addmod($sum, mulmod($f2, powmod($x, $k, $mod), $mod), $mod);
        ($f1, $f2) = ($f2, addmod($f1, $f2, $mod));
    }

    return $sum;
}

say modular_fibonacci_polynomial(7,      11, 100000);        #=> 57683
say modular_fibonacci_polynomial(10**15, 13, 6227020800);    #=> 4631902275
