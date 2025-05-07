#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 07 February 2019
# https://github.com/trizen

# A sublinear algorithm for computing the partial sums of the Jordan totient function times k^m.

# The partial sums of the Jordan totient function is defined as:
#
#   a(n,j,m) = Sum_{k=1..n} k^m * J_j(k)
#
# where J_j(k) is the Jordan totient function.

# Example:
#   a(10^1, 2, 1) = 2431
#   a(10^2, 2, 1) = 21128719
#   a(10^3, 2, 1) = 208327305823
#   a(10^4, 2, 1) = 2080103011048135
#   a(10^5, 2, 1) = 20798025097513144783
#   a(10^6, 2, 1) = 207977166477794042245831
#   a(10^7, 2, 1) = 2079768770407248541815183631
#   a(10^8, 2, 1) = 20797684646417657386198683679183
#   a(10^9, 2, 1) = 207976843496387628847025371255443991

# General asymptotic formula:
#
#   Sum_{k=1..n} k^m * J_j(k)  ~  F_(m+j)(n) / zeta(j+1).
#
# where F_m(n) are the Faulhaber polynomials.

# OEIS sequences:
#   https://oeis.org/A321879 -- Partial sums of the Jordan function J_2(k), for 1 <= k <= n.
#   https://oeis.org/A002088 -- Sum of totient function: a(n) = Sum_{k=1..n} phi(k).
#   https://oeis.org/A064018 -- Sum of the Euler totients phi for 10^n.
#   https://oeis.org/A272718 -- Partial sums of gcd-sum sequence A018804.

# See also:
#   https://en.wikipedia.org/wiki/Faulhaber's_formula
#   https://en.wikipedia.org/wiki/Dirichlet_hyperbola_method
#   https://en.wikipedia.org/wiki/Jordan%27s_totient_function
#   https://trizenx.blogspot.com/2018/11/partial-sums-of-arithmetical-functions.html

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(faulhaber_sum ipow);
use ntheory qw(jordan_totient sqrtint rootint);

sub partial_sums_of_jordan_totient ($n, $j, $m) {
    my $s = sqrtint($n);

    my @jordan_sum_lookup = (0);
    my $lookup_size = 2 * rootint($n, 3)**2;

    foreach my $i (1 .. $lookup_size) {
        $jordan_sum_lookup[$i] = $jordan_sum_lookup[$i - 1] + ipow($i, $m) * jordan_totient($j, $i);
    }

    my %seen;

    sub ($n) {

        if ($n <= $lookup_size) {
            return $jordan_sum_lookup[$n];
        }

        if (exists $seen{$n}) {
            return $seen{$n};
        }

        my $s = sqrtint($n);
        my $T = faulhaber_sum($n, $m + $j);

        foreach my $k (2 .. int($n / ($s + 1))) {
            $T -= ipow($k, $m) * __SUB__->(int($n / $k));
        }

        foreach my $k (1 .. $s) {
            $T -= (faulhaber_sum(int($n / $k), $m) - faulhaber_sum(int($n / ($k + 1)), $m)) * $jordan_sum_lookup[$k];
        }

        $seen{$n} = $T;

    }->($n);
}

my $j = 2;
my $k = 1;

foreach my $n (1 .. 7) {    # takes ~2.9 seconds
    say "a(10^$n, $j, $k) = ", partial_sums_of_jordan_totient(10**$n, $j, $k);
}
