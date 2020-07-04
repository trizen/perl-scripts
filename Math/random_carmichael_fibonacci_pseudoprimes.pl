#!/usr/bin/perl

# Generate random Carmichael numbers of the form:
#   `n = p * (2*p - 1) * (3*p - 2) * (6*p - 5)`.

# About half of this numbers are also Fibonacci pseudoprimes, satisfying:
#   `Fibonacci(n - kronecker(n, 5)) = 0 (mod n)`.

use 5.010;
use strict;
use warnings;

use Math::GMPz;
use ntheory qw(is_prob_prime random_nbit_prime);

my $bits = 50;    # bits of p

foreach my $n (1 .. 1e6) {
    my $p = Math::GMPz->new(random_nbit_prime($bits));

    if (is_prob_prime(2 * $p - 1) && is_prob_prime(3 * $p - 2) && is_prob_prime(6 * $p - 5)) {
        say $p * ($p * 2 - 1) * ($p * 3 - 2) * ($p * 6 - 5);
    }
}
