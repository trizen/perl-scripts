#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 16 March 2019
# https://github.com/trizen

# Efficient algorithm for determinining if a given number is squarefree over a squarefree product.

# Algorithm:
#     1. Let n be the number to be tested.
#     2. Let k be the product of the primes <= B.
#     3. Compute the greatest common divisor: g = gcd(n, k)
#     4. If g is greater than 1, then n = r*g.
#        - If r = 1, then n is B-smooth and squarefree.
#        - Otherwise, if gcd(r, k) > 1, then n is not squarefree.
#     5. If this step is reached, then n is not B-smooth.

use 5.020;
use strict;
use warnings;

use Math::GMPz;
use ntheory qw(primorial factor);
use experimental qw(signatures);

sub is_squarefree_over_prod ($n, $k) {

    state $g = Math::GMPz::Rmpz_init_nobless();
    state $t = Math::GMPz::Rmpz_init_nobless();

    # Compute the greatest common divisor: g = gcd(n, k)
    Math::GMPz::Rmpz_set($t, $n);
    Math::GMPz::Rmpz_gcd($g, $t, $k);

    if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {

        # If g is greater than 1, then n = r*g.
        Math::GMPz::Rmpz_divexact($t, $t, $g);

        # If r = 1, then n is squarefree.
        return 1 if Math::GMPz::Rmpz_cmp_ui($t, 1) == 0;

        # Otherwise, if gcd(r, k) > 1, then n is not squarefree.
        Math::GMPz::Rmpz_gcd($g, $t, $k);

        if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
            return 0;
        }
    }

    # If this step is reached, then n is not B-smooth.
    return 0;
}

my $k = Math::GMPz->new(primorial(19));    # product of primes <= 19

foreach my $n (1 .. 100) {
    if (is_squarefree_over_prod(Math::GMPz->new($n), $k)) {
        say "$n is 19-squarefree: prod(", join(', ', factor($n)), ")";
    }
}
