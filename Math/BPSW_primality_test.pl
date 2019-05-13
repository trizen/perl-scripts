#!/usr/bin/perl

# The Baillie-PSW primality test, named after Robert Baillie, Carl Pomerance, John Selfridge, and Samuel Wagstaff.

# No counter-examples are known to this test.

# Algorithm: given an odd integer n, that is not a perfect power:
#   1. Perform a (strong) base-2 Fermat test.
#   2. Find the first D in the sequence 5, −7, 9, −11, 13, −15, ... for which the Jacobi symbol (D/n) is −1.
#      Set P = 1 and Q = (1 − D) / 4.
#   3. Perform a strong Lucas probable prime test on n using parameters D, P, and Q.

# See also:
#   https://en.wikipedia.org/wiki/Lucas_pseudoprime
#   https://en.wikipedia.org/wiki/Baillie%E2%80%93PSW_primality_test

use 5.020;
use warnings;
use experimental qw(signatures);

use Math::AnyNum qw(
    is_prime is_power is_congruent
    kronecker powmod as_bin bit_scan1
);

sub findQ($n) {

    # Find first D for which kronecker(D, n) == -1
    for (my $k = 2 ; ; ++$k) {
        my $D = (-1)**$k * (2 * $k + 1);
        if (kronecker($D, $n) == -1) {
            return ((1 - $D) / 4);
        }
    }
}

sub BPSW_primality_test($n) {

    return 0 if $n <= 1;
    return 1 if $n == 2;

    return 0 if !($n & 1);
    return 0 if is_power($n);

    # Fermat base-2 test
    powmod(2, $n - 1, $n) == 1 or return 0;

    # Perform a strong Lucas probable test
    my $Q = findQ($n);
    my $d = $n + 1;
    my $s = bit_scan1($d, 0);
    my $t = $d >> ($s+1);

    my ($U1     ) = (1   );
    my ($V1, $V2) = (2, 1);
    my ($Q1, $Q2) = (1, 1);

    foreach my $bit (split(//, as_bin($t))) {

        $Q1 = ($Q1 * $Q2) % $n;

        if ($bit) {
            $Q2 = ($Q1 * $Q) % $n;
            $U1 = ($U1 * $V2) % $n;
            $V1 = ($V2 * $V1 - $Q1) % $n;
            $V2 = ($V2 * $V2 - ($Q2 + $Q2)) % $n;
        }
        else {
            $Q2 = $Q1;
            $U1 = ($U1 * $V1 - $Q1) % $n;
            $V2 = ($V2 * $V1 - $Q1) % $n;
            $V1 = ($V1 * $V1 - ($Q2 + $Q2)) % $n;
        }
    }

    $Q1 = ($Q1 * $Q2) % $n;
    $Q2 = ($Q1 * $Q) % $n;
    $U1 = ($U1 * $V1 - $Q1) % $n;
    $V1 = ($V2 * $V1 - $Q1) % $n;
    $Q1 = ($Q1 * $Q2) % $n;

    return 1 if is_congruent($U1, 0, $n);
    return 1 if is_congruent($V1, 0, $n);

    for (1 .. $s) {

        $V1 = ($V1 * $V1 - 2 * $Q1) % $n;
        $Q1 = ($Q1 * $Q1) % $n;

        return 1 if is_congruent($V1, 0, $n);
    }

    return 0;
}

#
## Run some tests
#

my $from  = 1;
my $to    = 1e5;
my $count = 0;

foreach my $n ($from .. $to) {
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

say "There are $count primes between $from and $to.";
