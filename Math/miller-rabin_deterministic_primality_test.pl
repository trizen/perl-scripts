#!/usr/bin/perl

# Miller-Rabin deterministic primality test.

# Theorem (Miller, 1976):
#   If the Generalized Riemann hypothesis is true, then there is a constant C such that
#   primality of `n` is the same as every a <= C*(log(n))^2 being a Miller-Rabin witness for `n`.

# Bach (1984) showed that we can use C = 2.

# Assuming the GRH, this primality test runs in polynomial time.

# See also:
#   https://en.wikipedia.org/wiki/Miller%E2%80%93Rabin_primality_test

use 5.010;
use strict;
use warnings;

use List::Util qw(min);
use ntheory qw(valuation powmod);

sub is_provable_prime {
    my ($n) = @_;

    return 1 if $n == 2;
    return 0 if $n < 2 or $n % 2 == 0;

    my $d = $n - 1;
    my $s = valuation($d, 2);

    $d >>= $s;

  LOOP: for my $k (2 .. min($n-1, 2*log($n)**2)) {

        my $x = powmod($k, $d, $n);
        next if $x == 1 or $x == $n - 1;

        for (1 .. $s - 1) {
            $x = ($x * $x) % $n;
            return 0  if $x == 1;
            next LOOP if $x == $n - 1;
        }
        return 0;
    }
    return 1;
}

my $count = 0;
my $limit = 100000;

foreach my $n (1 .. $limit) {
    if (is_provable_prime($n)) {
        ++$count;
    }
}

say "There are $count primes <= $limit";
