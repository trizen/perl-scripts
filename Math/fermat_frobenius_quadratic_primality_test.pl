#!/usr/bin/perl

# A very strong primality test, with no counter-examples known.

# Similar to the Baillie–PSW primality test, but instead of performing a Lucas test, we perform a Frobenius quadratic test.

# Given an odd integer n, that is not a perfect power:
#   1. Perform a base-2 Fermat test.
#   2. Find the first D in the sequence 5, −7, 9, −11, 13, −15, ... for which the Jacobi symbol (D/n) is −1.
#      Set P = 1 and Q = (1 − D) / 4.
#   3. Perform a Frobenius quadratic test with x^2-Px+Q.

# See also:
#   https://oeis.org/A212424
#   https://en.wikipedia.org/wiki/Frobenius_pseudoprime
#   https://en.wikipedia.org/wiki/Quadratic_Frobenius_test
#   https://en.wikipedia.org/wiki/Baillie%E2%80%93PSW_primality_test

use 5.020;
use warnings;

use experimental qw(signatures);

use ntheory qw(
    kronecker is_power is_prime
    is_frobenius_pseudoprime powmod
);

sub strong_frobenius_primality_test ($n) {

    return 0 if ($n <= 1);
    return 1 if ($n == 2);
    return 0 if is_power($n);

    powmod(2, $n - 1, $n) == 1 or return 0;

    my ($P, $Q) = (1, 0);

    for (my $k = 2 ; ; ++$k) {
        my $D = (-1)**$k * (2 * $k + 1);

        if (kronecker($D, $n) == -1) {
            $Q = (1 - $D) / 4;
            last;
        }
    }

    is_frobenius_pseudoprime($n, $P, $Q);
}

my $count = 0;
foreach my $n (1 .. 1e6) {
    if (strong_frobenius_primality_test($n)) {
        if (not is_prime($n)) {
            say "Counter-example: $n";
        }
        ++$count;
    }
    elsif (is_prime($n)) {
        say "Missed a prime: $n";
    }
}

say "There are $count primes bellow 10^6";
