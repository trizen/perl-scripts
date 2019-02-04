#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 04 February 2019
# https://github.com/trizen

# A sublinear algorithm for computing the partial sums of the Jordan totient function.

# The partial sums of the Jordan totient function is defined as:
#
#   a_m(n) = Sum_{k=1..n} J_m(k)
#
# where J_m(k) is the Jordan totient function.

# Recursive formula:
#
#   a_m(n) = F_m(n) - Sum_{k=2..sqrt(n)} a_m(floor(n/k)) - Sum_{k=1..floor(n/sqrt(n))-1} a_m(k) * (floor(n/k) - floor(n/(k+1)))
#
# where F_m(x) are Faulhaber's polynomials.

# Example for a_2(n) = Sum_{k=1..n} J_2(k):
#    a_2(10^1) = 312
#    a_2(10^2) = 280608
#    a_2(10^3) = 277652904
#    a_2(10^4) = 277335915120
#    a_2(10^5) = 277305865353048
#    a_2(10^6) = 277302780859485648
#    a_2(10^7) = 277302491422450102032
#    a_2(10^8) = 277302460845902192282712
#    a_2(10^9) = 277302457878113251222146576

# Asymptotic formula:
#   Sum_{k=1..n} J_2(k) ~ n^3 / (3*zeta(3))

# In general, for m>=1:
#   Sum_{k=1..n} J_m(k) ~ n^(m+1) / ((m+1) * zeta(m+1))

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

use Math::GMPz qw();
use Math::AnyNum qw(faulhaber_sum);
use ntheory qw(sqrtint rootint jordan_totient);

sub partial_sums_of_jordan_totient ($n, $m) {
    my $s = sqrtint($n);

    my $lookup_size       = 2 * rootint($n, 3)**2;
    my @jordan_sum_lookup = (Math::GMPz->new(0));

    foreach my $i (1 .. $lookup_size) {
        $jordan_sum_lookup[$i] = $jordan_sum_lookup[$i - 1] + jordan_totient($m, $i);
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
        my $A = ${faulhaber_sum($n, $m)};

        foreach my $k (2 .. $s) {
            $A -= __SUB__->(int($n / $k));
        }

        foreach my $k (1 .. int($n / $s) - 1) {
            $A -= (int($n / $k) - int($n / ($k + 1))) * __SUB__->($k);
        }

        $seen{$n} = $A;

      }->($n);
}

foreach my $n (1 .. 8) {    # takes ~1.5 seconds
    say "a_2(10^$n) = ", partial_sums_of_jordan_totient(10**$n, 2);
}
