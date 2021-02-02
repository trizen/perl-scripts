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
use ntheory qw(:all);

my @bases = (2, 3, 5);    # Miller-Rabin pseudoprimes to these bases
my $bits  = 50;           # bits of p

foreach my $n (1 .. 1e6) {
    my $p = Math::GMPz->new(random_nbit_prime($bits));

    if (is_prob_prime(2 * $p - 1)) {
        my $n = $p * ($p * 2 - 1);

        if (is_strong_pseudoprime($n, @bases)) {
            say $n;
        }
    }
}
