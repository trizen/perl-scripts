#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 05 April 2022
# https://github.com/trizen

# A sublinear algorithm for computing the partial sums of the Euler totient function.

# The partial sums of the Euler totient function is defined as:
#
#   a(n,m) = Sum_{k=1..n} phi(k)
#
# where phi(k) is the Euler totient function.

# Example:
#   a(10^1)  = 32
#   a(10^2)  = 3044
#   a(10^3)  = 304192
#   a(10^4)  = 30397486
#   a(10^5)  = 3039650754
#   a(10^6)  = 303963552392
#   a(10^7)  = 30396356427242
#   a(10^8)  = 3039635516365908
#   a(10^9)  = 303963551173008414
#   a(10^10) = 30396355092886216366

# General asymptotic formula:
#
#   Sum_{k=1..n} k^m * phi(k)  ~  F_{m+1}(n) / zeta(2).
#
# where F_m(n) are the Faulhaber polynomials.

# OEIS sequences:
#   https://oeis.org/A011755 -- Sum_{k=1..n} k*phi(k).
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

use ntheory qw(:all);
use experimental qw(signatures);

sub triangular ($n) {
    divint(mulint($n, $n + 1), 2);
}

sub partial_sums_of_euler_totient ($n) {
    my $s = sqrtint($n);

    my @euler_sum_lookup = (0);

    my $lookup_size = int(2 * rootint($n, 3)**2);
    my @euler_phi   = euler_phi(0, $lookup_size);

    foreach my $i (1 .. $lookup_size) {
        $euler_sum_lookup[$i] = addint($euler_sum_lookup[$i - 1], $euler_phi[$i]);
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
        my $T = triangular($n);

        foreach my $k (2 .. divint($n, $s + 1)) {
            $T = subint($T, __SUB__->(divint($n, $k)));
        }

        my $prev = $n;

        foreach my $k (1 .. $s) {
            my $curr = divint($n, $k + 1);
            $T    = subint($T, mulint(subint($prev, $curr), $euler_sum_lookup[$k]));
            $prev = $curr;
        }

        $seen{$n} = $T;

    }->($n);
}

foreach my $n (1 .. 8) {    # takes less than 1 second
    say "a(10^$n) = ", partial_sums_of_euler_totient(powint(10, $n));
}
