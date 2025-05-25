#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 25 May 2025
# https://github.com/trizen

# A sublinear algorithm for computing the partial sums of the generalized gcd-sum function, using Dirichlet's hyperbola method.

# Generalized Pillai's function:
#   pillai(n,k) = Sum_{d|n} mu(n/d) * d^k * tau(d)

# Multiplicative formula for Sum_{1 <= x_1, x_2, ..., x_k <= n} gcd(x_1, x_2, ..., x_k, n)^k:
#   a(p^e) = (e - e/p^k + 1) * p^(k*e) = p^((e - 1) * k) * (p^k + e*(p^k - 1))

# The partial sums of the gcd-sum function is defined as:
#
#   a(n) = Sum_{k=1..n} Sum_{d|k} d*phi(k/d)
#
# where phi(k) is the Euler totient function.

# Also equivalent with:
#   a(n) = Sum_{j=1..n} Sum_{i=1..j} gcd(i, j)

# Based on the formula:
#   a(n) = (1/2)*Sum_{k=1..n} phi(k) * floor(n/k) * floor(1+n/k)

# Generalized formula:
#   a(n,k) = Sum_{x=1..n} J_k(x) * F_k(floor(n/x))
# where F_k(n) are the Faulhaber polynomials: F_k(n) = Sum_{x=1..n} x^k.

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

#   a(10^1, 2) = 1106
#   a(10^2, 2) = 1598361
#   a(10^3, 2) = 2193987154
#   a(10^4, 2) = 2828894776292
#   a(10^5, 2) = 3466053625977000
#   a(10^6, 2) = 4104546122851466704
#   a(10^7, 2) = 4742992578252739471520
#   a(10^8, 2) = 5381500783126483704718848
#   a(10^9, 2) = 6020011093886996189443484608

# OEIS sequences:
#   https://oeis.org/A272718 -- Partial sums of gcd-sum sequence A018804.
#   https://oeis.org/A018804 -- Pillai's arithmetical function: Sum_{k=1..n} gcd(k, n).

# See also:
#   https://en.wikipedia.org/wiki/Dirichlet_hyperbola_method
#   https://trizenx.blogspot.com/2018/11/partial-sums-of-arithmetical-functions.html

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(faulhaber_sum ipow);
use ntheory      qw(jordan_totient sqrtint rootint);

sub partial_sums_of_gcd_sum_function($n, $m) {

    my $s                  = sqrtint($n);
    my @totient_sum_lookup = (0);

    my $lookup_size    = 2 + 2 * rootint($n, 3)**2;
    my @jordan_totient = (0);

    foreach my $x (1 .. $lookup_size) {
        push @jordan_totient, jordan_totient($m, $x);
    }

    foreach my $i (1 .. $lookup_size) {
        $totient_sum_lookup[$i] = $totient_sum_lookup[$i - 1] + $jordan_totient[$i];
    }

    my %seen;

    my sub totient_partial_sum($n) {

        if ($n <= $lookup_size) {
            return $totient_sum_lookup[$n];
        }

        if (exists $seen{$n}) {
            return $seen{$n};
        }

        my $s = sqrtint($n);
        my $T = ${faulhaber_sum($n, $m)};

        foreach my $k (2 .. int($n / ($s + 1))) {
            $T -= __SUB__->(int($n / $k));
        }

        foreach my $k (1 .. $s) {
            $T -= (int($n / $k) - int($n / ($k + 1))) * $totient_sum_lookup[$k];
        }

        $seen{$n} = $T;
    }

    my $A = 0;

    foreach my $k (1 .. $s) {
        my $t = int($n / $k);
        $A += ${ipow($k, $m)} * totient_partial_sum($t) + $jordan_totient[$k] * ${faulhaber_sum($t, $m)};
    }

    my $T = ${faulhaber_sum($s, $m)};
    my $C = totient_partial_sum($s);

    return ($A - $T * $C);
}

foreach my $n (1 .. 8) {    # takes less than 1 second
    say "a(10^$n, 1) = ", partial_sums_of_gcd_sum_function(10**$n, 1);
}

say '';

foreach my $n (1 .. 8) {    # takes less than 1 second
    say "a(10^$n, 2) = ", partial_sums_of_gcd_sum_function(10**$n, 2);
}
