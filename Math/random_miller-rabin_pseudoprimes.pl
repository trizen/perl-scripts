#!/usr/bin/perl

# Generate random probable Miller-Rabin pseudoprimes of the form:
#
#   `n = p * (2*p - 1)`
#
# where `2*p - 1` is also prime.

use 5.010;
use strict;
use warnings;

use Math::GMPz;
use ntheory qw(is_prob_prime random_nbit_prime);

my $reps = 3;     # number of bases to test
my $bits = 50;    # bits of p

foreach my $n (1 .. 1e6) {
    my $p = Math::GMPz->new(random_nbit_prime($bits));

    if (is_prob_prime(2 * $p - 1)) {
        my $n = $p * ($p * 2 - 1);

        if (Math::GMPz::Rmpz_probab_prime_p($n, $reps)) {
            say $n;
        }
    }
}
