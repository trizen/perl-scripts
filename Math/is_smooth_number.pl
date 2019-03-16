#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 25 October 2018
# https://github.com/trizen

# A new algorithm for testing N for B-smoothness, given the product of a subset of primes <= B.
# Returns a true value when N is the product of a subset of prime factors of B.
# This algorithm can be useful in some modern integer factorization algorithms.

# Algorithm:
#     1. Let n be the number to be tested.
#     2. Let k be the product of the primes in the factor base.
#     3. Compute the greatest common divisor: g = gcd(n, k)
#     4. If g is greater than 1, then n = r * g^e, for some e >= 1.
#        - If r = 1, then n is smooth over the factor base.
#        - Otherwise, set n = r and go to step 3.
#     5. If this step is reached, then n is not smooth.

use 5.020;
use warnings;

use experimental qw(signatures);
use ntheory qw(gcd valuation primorial factor);

sub is_smooth_over_prod ($n, $k) {

    for (my $g = gcd($n, $k) ; $g > 1 ; $g = gcd($n, $k)) {
        $n /= $g;                         # remove one divisor g
        $n /= $g while ($n % $g == 0);    # remove any divisibility by g
        return 1 if ($n == 1);            # smooth if n == 1
    }

    return 0;
}

# Example for identifying 19-smooth numbers
my $k = primorial(19);                    # product of primes <= 19

for my $n (1 .. 1000) {
    say($n, " = prod(", join(', ', factor($n)), ")") if is_smooth_over_prod($n, $k);
}
