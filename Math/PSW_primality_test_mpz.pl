#!/usr/bin/perl

# The PSW primality test, named after Carl Pomerance, John Selfridge, and Samuel Wagstaff.

# No counter-examples are known to this test.

# Algorithm: given an odd integer n, that is not a perfect power:
#   1. Perform a base-2 Fermat test.
#   2. Find the first P>0 such that kronecker(n, P^2 + 4) = -1.
#   3. If the Lucas U sequence: U(P, -1, n+1) = 0 (mod n), then n is probably prime.

# See also:
#   https://en.wikipedia.org/wiki/Lucas_pseudoprime
#   https://en.wikipedia.org/wiki/Baillie%E2%80%93PSW_primality_test

use 5.020;
use warnings;
use experimental qw(signatures);

use Math::GMPz;
use ntheory qw(is_prime lucas_sequence);

sub PSW_primality_test ($n) {

    $n = Math::GMPz->new("$n");

    return 0 if Math::GMPz::Rmpz_cmp_ui($n, 1) <= 0;
    return 1 if Math::GMPz::Rmpz_cmp_ui($n, 2) == 0;
    return 0 if Math::GMPz::Rmpz_perfect_power_p($n);

    my $d = Math::GMPz::Rmpz_init();
    my $t = Math::GMPz::Rmpz_init_set_ui(2);

    # Fermat base-2 test
    Math::GMPz::Rmpz_sub_ui($d, $n, 1);
    Math::GMPz::Rmpz_powm($t, $t, $d, $n);
    Math::GMPz::Rmpz_cmp_ui($t, 1) and return 0;

    # Find P such that kronecker(n, P^2 + 4) = -1.
    my $P;
    for (my $k = 1 ; ; ++$k) {
        if (Math::GMPz::Rmpz_kronecker_ui($n, $k * $k + 4) == -1) {
            $P = $k;
            last;
        }
    }

    # If LucasU(P, -1, n+1) = 0 (mod n), then n is probably prime.
    (lucas_sequence($n, $P, -1, $n + 1))[0] == 0;
}

#
## Run some tests
#

my $from  = 1;
my $to    = 1e5;
my $count = 0;

foreach my $n ($from .. $to) {
    if (PSW_primality_test($n)) {
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
