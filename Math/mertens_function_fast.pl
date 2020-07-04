#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 04 February 2019
# https://github.com/trizen

# A sublinear algorithm for computing the Mertens function (partial sums of the Möbius function).

# Defined as:
#
#   M(n) = Sum_{k=1..n} μ(k)
#
# where μ(k) is the Möbius function.

# Example:
#   M(10^1) = -1
#   M(10^2) = 1
#   M(10^3) = 2
#   M(10^4) = -23
#   M(10^5) = -48
#   M(10^6) = 212
#   M(10^7) = 1037
#   M(10^8) = 1928
#   M(10^9) = -222

# OEIS sequences:
#   https://oeis.org/A008683 -- Möbius (or Moebius) function mu(n).
#   https://oeis.org/A084237 -- M(10^n), where M(n) is Mertens's function.

# See also:
#   https://en.wikipedia.org/wiki/Mertens_function
#   https://en.wikipedia.org/wiki/M%C3%B6bius_function

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(moebius sqrtint rootint);

sub mertens_function($n) {

    my $lookup_size = 2 * rootint($n, 3)**2;

    my @moebius_lookup = moebius(0, $lookup_size);
    my @mertens_lookup = (0);

    foreach my $i (1 .. $lookup_size) {
        $mertens_lookup[$i] = $mertens_lookup[$i - 1] + $moebius_lookup[$i];
    }

    my %seen;

    sub ($n) {

        if ($n <= $lookup_size) {
            return $mertens_lookup[$n];
        }

        if (exists $seen{$n}) {
            return $seen{$n};
        }

        my $s = sqrtint($n);
        my $M = 1;

        foreach my $k (2 .. int($n / ($s + 1))) {
            $M -= __SUB__->(int($n / $k));
        }

        foreach my $k (1 .. $s) {
            $M -= $mertens_lookup[$k] * (int($n / $k) - int($n / ($k + 1)));
        }

        $seen{$n} = $M;

    }->($n);
}

foreach my $n (1 .. 9) {    # takes ~1.6 seconds
    say "M(10^$n) = ", mertens_function(10**$n);
}
