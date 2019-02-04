#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 04 February 2019
# https://github.com/trizen

# A sublinear algorithm for computing the partial sums of the Euler totient function.

# The partial sums of the Euler totient function is defined as:
#
#   a(n) = Sum_{k=1..n} phi(k)
#
# where phi(k) is the Euler totient function.

# Recursive formula:
#   a(n) = n*(n+1)/2 - Sum_{k=2..sqrt(n)} a(floor(n/k)) - Sum_{k=1..floor(n/sqrt(n))-1} a(k) * (floor(n/k) - floor(n/(k+1)))

# Example:
#   a(10^1) = 32
#   a(10^2) = 3044
#   a(10^3) = 304192
#   a(10^4) = 30397486
#   a(10^5) = 3039650754
#   a(10^6) = 303963552392
#   a(10^7) = 30396356427242
#   a(10^8) = 3039635516365908
#   a(10^9) = 303963551173008414

# OEIS sequences:
#   https://oeis.org/A002088 -- Sum of totient function: a(n) = Sum_{k=1..n} phi(k).
#   https://oeis.org/A064018 -- Sum of the Euler totients phi for 10^n.
#   https://oeis.org/A272718 -- Partial sums of gcd-sum sequence A018804.

# See also:
#   https://en.wikipedia.org/wiki/Dirichlet_hyperbola_method
#   https://trizenx.blogspot.com/2018/11/partial-sums-of-arithmetical-functions.html

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(euler_phi sqrtint rootint);

sub partial_sums_of_euler_totient($n) {
    my $s = sqrtint($n);

    my @euler_sum_lookup = (0);

    my $lookup_size = 2 * rootint($n, 3)**2;
    my @euler_phi   = euler_phi(0, $lookup_size);

    foreach my $i (1 .. $lookup_size) {
        $euler_sum_lookup[$i] = $euler_sum_lookup[$i - 1] + $euler_phi[$i];
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
        my $T = ($n * ($n + 1)) >> 1;

        my $A = 0;

        foreach my $k (2 .. $s) {
            $A += __SUB__->(int($n / $k));
        }

        my $B = 0;
        foreach my $k (1 .. int($n / $s) - 1) {
            $B += (int($n / $k) - int($n / ($k + 1))) * __SUB__->($k);
        }

        $seen{$n} = $T - $A - $B;

    }->($n);
}

foreach my $n (1 .. 8) {    # takes less than 1 second
    say "a(10^$n) = ", partial_sums_of_euler_totient(10**$n);
}
