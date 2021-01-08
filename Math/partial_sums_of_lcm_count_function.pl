#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 09 January 2021
# https://github.com/trizen

# Let f(n) be the number of couples (x,y) with x and y positive integers, x ≤ y and the least common multiple of x and y equal to n.

# Let a(n) = A007875(n), with a(1) = 1, for n > 1 (due to Vladeta Jovovic, Jan 25 2002):
#   a(n) = (1/2)*Sum_{d|n} abs(mu(d))
#        = 2^(omega(n)-1)
#        = usigma_0(n)/2

# This gives us f(n) as:
#   f(n) = Sum_{d|n} a(d)

# This script implements a sub-linear formula for computing partial sums of f(n):
#   S(n) = Sum_{k=1..n} f(k)
#        = Sum_{k=1..n} Sum_{d|k} a(d)
#        = Sum_{k=1..n} a(k) * floor(n/k)

# See also:
#   https://oeis.org/A007875
#   https://oeis.org/A064608
#   https://oeis.org/A182082

# Problem from:
#   https://projecteuler.net/problem=379

# Several values for S(10^n):
#   S(10^1)  = 29
#   S(10^2)  = 647
#   S(10^3)  = 11751
#   S(10^4)  = 186991
#   S(10^5)  = 2725630
#   S(10^6)  = 37429395
#   S(10^7)  = 492143953
#   S(10^8)  = 6261116500
#   S(10^9)  = 77619512018
#   S(10^10) = 942394656385
#   S(10^11) = 11247100884096

use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub S ($n) {

    my $lookup_size = 2 + 2 * rootint($n, 3)**2;

    $lookup_size = 50000000    if ($lookup_size > 50000000);
    $lookup_size = sqrtint($n) if ($lookup_size < sqrtint($n));

    my @omega_lookup     = (0);
    my @omega_sum_lookup = (0);

    for my $k (1 .. $lookup_size) {
        $omega_lookup[$k]     = ($k == 1) ? 0 : (1 << (factor_exp($k) - 1));
        $omega_sum_lookup[$k] = $omega_sum_lookup[$k - 1] + $omega_lookup[$k];
    }

    my $s  = sqrtint($n);
    my @mu = moebius(0, $s);

    my sub R ($n) {

        if ($n <= $lookup_size) {
            return $omega_sum_lookup[$n];
        }

        my $total = 0;

        foreach my $k (1 .. sqrtint($n)) {

            $mu[$k] || next;

            my $t = 0;
            my $r = sqrtint(divint($n, $k * $k));

            foreach my $j (1 .. $r) {
                $t += divint($n, $j * $k * $k);
            }

            $total += $mu[$k] * (2 * $t - $r * $r);
        }

        return (($total - 1) >> 1);
    }

    my $total = 0;

    for my $k (1 .. $s) {
        $total += $omega_lookup[$k] * divint($n, $k);
        $total += R(divint($n, $k));
    }

    $total -= R($s) * $s;

    return $total + $n;
}

foreach my $n (1 .. 9) {
    say "S(10^$n) = ", S(10**$n);
}
