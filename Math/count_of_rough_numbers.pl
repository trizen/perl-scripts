#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 20 July 2020
# https://github.com/trizen

# Count the number of B-rough numbers <= n.

# See also:
#   https://en.wikipedia.org/wiki/Rough_number

use 5.020;
use ntheory qw(:all);
use experimental qw(signatures);

sub rough_count ($n, $p) {
    sub ($n, $p) {

        if ($p > sqrtint($n)) {
            return 1;
        }

        if ($p == 2) {
            return ($n >> 1);
        }

        if ($p == 3) {
            my $t = $n / 3;
            return ($t - ($t >> 1));
        }

        my $u = 0;
        my $t = $n / $p;

        for (my $q = 2 ; $q < $p ; $q = next_prime($q)) {

            my $v = __SUB__->($t - ($t % $q), $q);

            if ($v == 1) {
                $u += prime_count($q, $p - 1);
                last;
            }
            else {
                $u += $v;
            }
        }

        $t - $u;
    }->($n * $p, $p);
}

foreach my $p (@{primes(30)}) {
    say "Φ(10^n, $p) for n <= 10: [", join(', ', map { rough_count(powint(10, $_), $p) } 0 .. 10), "]";
}
