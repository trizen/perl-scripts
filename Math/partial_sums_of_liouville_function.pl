#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 04 April 2019
# https://github.com/trizen

# A sublinear algorithm for computing the summatory function of the Liouville function (partial sums of the Liouville function).

# Defined as:
#
#   L(n) = Sum_{k=1..n} λ(k)
#
# where λ(k) is the Liouville function.

# Example:
#   L(10^1) = 0
#   L(10^2) = -2
#   L(10^3) = -14
#   L(10^4) = -94
#   L(10^5) = -288
#   L(10^6) = -530
#   L(10^7) = -842
#   L(10^8) = -3884
#   L(10^9) = -25216
#   L(10^10) = -116026

# OEIS sequences:
#   https://oeis.org/A008836 -- Liouville's function lambda(n) = (-1)^k, where k is number of primes dividing n (counted with multiplicity).
#   https://oeis.org/A090410 -- L(10^n), where L(n) is the summatory function of the Liouville function.

# See also:
#   https://en.wikipedia.org/wiki/Liouville_function

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(liouville sqrtint rootint);

sub liouville_function_sum($n) {

    my $lookup_size = 2 * rootint($n, 3)**2;

    my @lambda_lookup = (0);
    my @liouville_lookup = (0);

    foreach my $i (1 .. $lookup_size) {
        $liouville_lookup[$i] = $liouville_lookup[$i - 1] + ($lambda_lookup[$i] = liouville($i));
    }

    my %seen;

    sub ($n) {

        if ($n <= $lookup_size) {
            return $liouville_lookup[$n];
        }

        if (exists $seen{$n}) {
            return $seen{$n};
        }

        my $s = sqrtint($n);
        my $M = $s;

        foreach my $k (2 .. int($n / ($s + 1))) {
            $M -= __SUB__->(int($n / $k));
        }

        foreach my $k (1 .. $s) {
            $M -= $liouville_lookup[$k] * (int($n / $k) - int($n / ($k + 1)));
        }

        $seen{$n} = $M;

    }->($n);
}

foreach my $n (1 .. 9) {    # takes ~2.6 seconds
    say "L(10^$n) = ", liouville_function_sum(10**$n);
}
