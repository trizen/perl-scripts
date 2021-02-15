#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 14 February 2021
# https://github.com/trizen

# Generate k-almost prime numbers <= n. (not in sorted order)

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime

use 5.020;
use ntheory qw(:all);
use experimental qw(signatures);

sub almost_prime_numbers ($n, $k, $callback) {

    sub ($m, $p, $r) {

        my $s = rootint(divint($n, $m), $r);

        if ($r == 1) {

            forprimes {
                $callback->(mulint($m, $_));
            } $p, divint($n, $m);

            return;
        }

        for (my $q = $p ; $q <= $s ; $q = next_prime($q)) {
            __SUB__->(mulint($m, $q), $q, $r - 1);
        }
    }->(1, 2, $k);
}

# Generate all the numbers k <= 100 for which bigomega(k) = 4
almost_prime_numbers(100, 4, sub ($n) { say $n });
