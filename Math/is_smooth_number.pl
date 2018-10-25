#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 25 October 2018
# https://github.com/trizen

# A new algorithm for testing N for B-smoothness, given the product of a subset of primes <= B.
# Returns a true value when N is the product of a subset of prime factors of B.
# This algorithm can be useful in some modern integer factorization algorithms.

use 5.020;
use warnings;

use experimental qw(signatures);
use ntheory qw(gcd valuation primorial factor);

sub is_smooth ($n, $k) {

    for (my $g = gcd($n, $k) ; $g > 1 ; $g = gcd($n, $k)) {
        $n /= $g;                         # remove one divisor g
        $n /= $g while ($n % $g == 0);    # remove any divisibily by g
        return 1 if ($n == 1);            # smooth if n == 1
    }

    return 0;
}

# Example for finding 19-smooth numbers
my $k = primorial(19);                    # product of primes <= 19

for my $n (1 .. 1000) {
    say($n, " = prod(", join(', ', factor($n)), ")") if is_smooth($n, $k);
}
