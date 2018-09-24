#!/usr/bin/perl

# The Baillie-PSW primality test, named after Robert Baillie, Carl Pomerance, John Selfridge, and Samuel Wagstaff.

# No counter-examples are known to this test.

# Algorithm: given an odd integer n, that is not a perfect power:
#   1. Perform a base-2 Fermat test.
#   2. Find the first D in the sequence 5, −7, 9, −11, 13, −15, ... for which the Jacobi symbol (D/n) is −1.
#      Set P = 1 and Q = (1 − D) / 4.
#   3. Perform a strong Lucas probable prime test on n using parameters D, P, and Q.

# See also:
#   https://oeis.org/A212424
#   https://en.wikipedia.org/wiki/Lucas_pseudoprime
#   https://en.wikipedia.org/wiki/Frobenius_pseudoprime
#   https://en.wikipedia.org/wiki/Quadratic_Frobenius_test
#   https://en.wikipedia.org/wiki/Baillie%E2%80%93PSW_primality_test

use 5.020;
use warnings;

use experimental qw(signatures);

use Math::AnyNum qw(
  valuation lucasUmod lucasVmod
  is_power is_prime powmod kronecker
);

sub BPSW_primality_test ($n) {

    return 0 if ($n <= 1);
    return 1 if ($n == 2);
    return 0 if is_power($n);

    powmod(2, $n - 1, $n) == 1 or return 0;

    my ($P, $Q, $D) = (1, 0);

    for (my $k = 2 ; ; ++$k) {
        $D = (-1)**$k * (2 * $k + 1);

        if (kronecker($D, $n) == -1) {
            $Q = (1 - $D) / 4;
            last;
        }
    }

    my $d = $n - kronecker($D, $n);
    my $s = valuation($d, 2);

    $d >>= $s;

    return 1 if lucasUmod($P, $Q, $d, $n) == 0;

    foreach my $r (0 .. $s - 1) {
        return 1 if lucasVmod($P, $Q, $d << ($s - $r - 1), $n) == 0;
    }

    return 0;
}

my $count = 0;
foreach my $n (1 .. 1e5) {
    if (BPSW_primality_test($n)) {
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
