#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 07 February 2019
# https://github.com/trizen

# A sublinear algorithm for computing the partial sums of the Euler totient function times k^m.

# The partial sums of the Euler totient function is defined as:
#
#   a(n,m) = Sum_{k=1..n} k^m * phi(k)
#
# where phi(k) is the Euler totient function.

# Example:
#    a(10^1, 1) = 217
#    a(10^2, 1) = 203085
#    a(10^3, 1) = 202870719
#    a(10^4, 1) = 202653667159
#    a(10^5, 1) = 202643891472849
#    a(10^6, 1) = 202642368741515819
#    a(10^7, 1) = 202642380629476099463
#    a(10^8, 1) = 202642367994273571457613
#    a(10^9, 1) = 202642367530671221417109931

# General asymptotic formula:
#
#   Sum_{k=1..n} k^m * phi(k)  ~  F_(m+1)(n) / zeta(2).
#
# where F_m(n) are the Faulhaber polynomials.

# OEIS sequences:
#   https://oeis.org/A002088 -- Sum of totient function: a(n) = Sum_{k=1..n} phi(k).
#   https://oeis.org/A064018 -- Sum of the Euler totients phi for 10^n.
#   https://oeis.org/A272718 -- Partial sums of gcd-sum sequence A018804.

# See also:
#   https://en.wikipedia.org/wiki/Faulhaber's_formula
#   https://en.wikipedia.org/wiki/Dirichlet_hyperbola_method
#   https://trizenx.blogspot.com/2018/11/partial-sums-of-arithmetical-functions.html

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(faulhaber_sum ipow);
use ntheory qw(euler_phi sqrtint rootint);

sub partial_sums_of_euler_totient ($n, $m) {
    my $s = sqrtint($n);

    my @euler_sum_lookup = (0);

    my $lookup_size = 2 * rootint($n, 3)**2;
    my @euler_phi   = euler_phi(0, $lookup_size);

    foreach my $i (1 .. $lookup_size) {
        $euler_sum_lookup[$i] = $euler_sum_lookup[$i - 1] + ipow($i, $m) * $euler_phi[$i];
    }

    my %seen;

    sub ($n) {

        if ($n <= $lookup_size) {
            return $euler_sum_lookup[$n];
        }

        if (exists $seen{$n}) {
            return $seen{$n};
        }

        my $s = sqrtint($n);
        my $T = faulhaber_sum($n, $m + 1);

        foreach my $k (2 .. int($n / ($s + 1))) {
            $T -= ipow($k, $m) * __SUB__->(int($n / $k));
        }

        foreach my $k (1 .. $s) {
            $T -= (faulhaber_sum(int($n / $k), $m) - faulhaber_sum(int($n / ($k + 1)), $m)) * __SUB__->($k);
        }

        $seen{$n} = $T;

    }->($n);
}

foreach my $n (1 .. 7) {    # takes ~2.8 seconds
    say "a(10^$n, 1) = ", partial_sums_of_euler_totient(10**$n, 1);
}
