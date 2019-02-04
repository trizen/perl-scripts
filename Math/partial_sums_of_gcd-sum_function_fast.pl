#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 04 February 2019
# https://github.com/trizen

# A sublinear algorithm for computing the partial sums of the gcd-sum function, using Dirichlet's hyperbola method.

# The partial sums of the gcd-sum function is defined as:
#
#   a(n) = Sum_{k=1..n} Sum_{d|k} d*phi(k/d)
#
# where phi(k) is the Euler totient function.

# Also equivalent with:
#   a(n) = Sum_{j=1..n} Sum_{i=1..j} gcd(i, j)

# Based on the formula:
#   a(n) = (1/2)*Sum_{k=1..n} phi(k) * floor(n/k) * floor(1+n/k)

# Example:
#   a(10^1) = 122
#   a(10^2) = 18065
#   a(10^3) = 2475190
#   a(10^4) = 317257140
#   a(10^5) = 38717197452
#   a(10^6) = 4571629173912
#   a(10^7) = 527148712519016
#   a(10^8) = 59713873168012716
#   a(10^9) = 6671288261316915052

# OEIS sequences:
#   https://oeis.org/A272718 -- Partial sums of gcd-sum sequence A018804.
#   https://oeis.org/A018804 -- Pillai's arithmetical function: Sum_{k=1..n} gcd(k, n).

# See also:
#   https://en.wikipedia.org/wiki/Dirichlet_hyperbola_method
#   https://trizenx.blogspot.com/2018/11/partial-sums-of-arithmetical-functions.html

use 5.010;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(euler_phi mertens moebius sqrtint rootint);

sub partial_sums_of_gcd_sum_function($n) {
    my $s = sqrtint($n);

    my @mertens_lookup   = (0);
    my @euler_sum_lookup = (0);

    my $lookup_size = rootint($n, 5)**4;

    my @moebius   = moebius(0, $lookup_size);
    my @euler_phi = euler_phi(0, $lookup_size);

    foreach my $i (1 .. $lookup_size) {
        $mertens_lookup[$i]   = $mertens_lookup[$i - 1] + $moebius[$i];
        $euler_sum_lookup[$i] = $euler_sum_lookup[$i - 1] + $euler_phi[$i];
    }

    my sub moebius_partial_sum($n) {
        ($n <= $lookup_size) ? $mertens_lookup[$n] : mertens($n);
    }

    my sub euler_phi_partial_sum($n) {

        if ($n <= $lookup_size) {
            return $euler_sum_lookup[$n];
        }

        my $s = sqrtint($n);
        my $A = 0;

        foreach my $k (1 .. $s) {
            my $t = int($n / $k);
            $A += $k * ($t <= $lookup_size ? $mertens_lookup[$t] : moebius_partial_sum($t)) +
              ($k <= $lookup_size ? $moebius[$k] : moebius($k)) * (($t * ($t + 1)) >> 1);
        }

        my $C = moebius_partial_sum($s) * (($s * ($s + 1)) >> 1);

        return ($A - $C);
    }

    my $A = 0;

    foreach my $k (1 .. $s) {
        my $t = int($n / $k);
        $A += $k * ($t <= $lookup_size ? $euler_sum_lookup[$t] : euler_phi_partial_sum($t)) +
          ($k <= $lookup_size ? $euler_phi[$k] : euler_phi($k)) * (($t * ($t + 1)) >> 1);
    }

    my $C = euler_phi_partial_sum($s) * (($s * ($s + 1)) >> 1);

    return ($A - $C);
}

foreach my $n (1 .. 7) {    # takes less than 1 second
    say "a(10^$n) = ", partial_sums_of_gcd_sum_function(10**$n);
}
