#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 05 April 2022
# https://github.com/trizen

# A sublinear algorithm for computing the partial sums of the Euler totient function times k.

# The partial sums of the Euler totient function is defined as:
#
#   a(n,m) = Sum_{k=1..n} k * phi(k)
#
# where phi(k) is the Euler totient function.

# Example:
#    a(10^1)  = 217
#    a(10^2)  = 203085
#    a(10^3)  = 202870719
#    a(10^4)  = 202653667159
#    a(10^5)  = 202643891472849
#    a(10^6)  = 202642368741515819
#    a(10^7)  = 202642380629476099463
#    a(10^8)  = 202642367994273571457613
#    a(10^9)  = 202642367530671221417109931
#    a(10^10) = 202642367286524384080814204093

# General asymptotic formula:
#
#   Sum_{k=1..n} k^m * phi(k)  ~  F_(m+1)(n) / zeta(2).
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

use experimental qw(signatures);
use ntheory qw(:all);

sub triangular ($n) {
    divint(mulint($n, $n + 1), 2);
}

sub square_pyramidal ($n) {
    divint(vecprod($n, $n + 1, mulint(2, $n) + 1), 6);
}

sub partial_sums_of_euler_totient ($n) {
    my $s = sqrtint($n);

    my @euler_sum_lookup = (0);

    my $lookup_size = int(2 * rootint($n, 3)**2);
    my @euler_phi   = euler_phi(0, $lookup_size);

    foreach my $i (1 .. $lookup_size) {
        $euler_sum_lookup[$i] = addint($euler_sum_lookup[$i - 1], mulint($i, $euler_phi[$i]));
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
        my $T = square_pyramidal($n);

        foreach my $k (2 .. divint($n, $s + 1)) {
            $T = subint($T, mulint($k, __SUB__->(divint($n, $k))));
        }

        my $prev = triangular($n);

        foreach my $k (1 .. $s) {
            my $curr = triangular(divint($n, $k + 1));
            $T    = subint($T, mulint(subint($prev, $curr), $euler_sum_lookup[$k]));
            $prev = $curr;
        }

        $seen{$n} = $T;

    }->($n);
}

foreach my $n (1 .. 8) {    # takes ~5 seconds
    say "a(10^$n) = ", partial_sums_of_euler_totient(powint(10, $n));
}
