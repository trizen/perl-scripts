#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 27 November 2018
# https://github.com/trizen

# A nice algorithm in terms of the prime-counting function for computing the sum of exponents in prime-power factorization of n!.

# Equivalent with:
#   a(n) = bigomega(n!)

# See also:
#   https://oeis.org/A025528
#   https://oeis.org/A022559
#   https://oeis.org/A071811
#   https://en.wikipedia.org/wiki/Prime_omega_function
#   https://en.wikipedia.org/wiki/Prime-counting_function
#   https://trizenx.blogspot.com/2018/11/partial-sums-of-arithmetical-functions.html

# Example:
#    a(10^1) = 15
#    a(10^2) = 239
#    a(10^3) = 2877
#    a(10^4) = 31985
#    a(10^5) = 343614
#    a(10^6) = 3626619
#    a(10^7) = 37861249
#    a(10^8) = 392351272
#    a(10^9) = 4044220058
#    a(10^10) = 41518796555
#    a(10^11) = 424904645958

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(vecsum logint sqrtint rootint prime_count forprimes);

sub prime_power_count($n) {
    vecsum(map { prime_count(rootint($n, $_)) } 1 .. logint($n, 2));
}

sub bigomega_of_factorial($n) {

    my $s = sqrtint($n);
    my $u = int($n / ($s + 1));

    my $total = 0;

    for my $k (1 .. $s) {
        $total += $k * (prime_power_count(int($n / $k)) - prime_power_count(int($n / ($k + 1))));
    }

    forprimes {
        foreach my $k (1 .. logint($u, $_)) {
            $total += int($n / $_**$k);
        }
    } $u;

    return $total;
}

for my $n (1 .. 10) {
    say "a(10^$n) = ", bigomega_of_factorial(10**$n);
}
