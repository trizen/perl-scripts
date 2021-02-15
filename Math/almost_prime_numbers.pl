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

    if ($k == 1) {
        forprimes {
            $callback->($_);
        } $n;
        return;
    }

    my $count = 0;

    sub ($m, $p, $r) {

        my $s = rootint(divint($n, $m), $r);

        if ($r == 2) {

            forprimes {
                my $u = mulint($m, $_);
                forprimes {
                    $callback->(mulint($u, $_));
                } $_, divint($n, $u);
            } $p, $s;

            return;
        }

        for (my $q = $p ; $q <= $s ; $q = next_prime($q)) {
            __SUB__->($m * $q, $q, $r - 1);
        }
    }->(1, 2, $k);

    return $count;
}

almost_prime_numbers(100, 4, sub ($n) { say $n });
