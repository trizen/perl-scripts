#!/usr/bin/perl

# The elliptic-curve factorization method (ECM), due to Hendrik Lenstra.

# Algorithm presented in the bellow video:
#   https://www.youtube.com/watch?v=2JlpeQWtGH8

# See also:
#   https://en.wikipedia.org/wiki/Lenstra_elliptic-curve_factorization

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(ipow gcd invmod);
use ntheory qw(primes prime_count is_prime_power logint);

sub ecm ($N, $zrange = 100, $plimit = 10000) {

    if (is_prime_power($N, \my $p)) {
        return $p;
    }

    state @primes;

    if (@primes != prime_count($plimit)) {
        @primes = @{primes($plimit)};
    }

    foreach my $z (-$zrange .. $zrange) {
        my $x = 0;
        my $y = 1;

        foreach my $p (@primes) {
            my $k = ipow($p, logint($plimit, $p));

            my ($xn, $yn);
            my ($sx, $sy, $t) = ($x, $y, $k);

            my $first = '1';

            while ($t) {

                if ($t->is_odd) {
                    if ($first) {
                        ($xn, $yn) = ($sx, $sy);
                        $first = '0';
                    }
                    else {
                        my $d = gcd($sx - $xn, $N);

                        if ($d > 1) {
                            $d == $N ? last : return $d;
                        }

                        my $u = invmod($sx - $xn, $N);
                        my $L = ($u * ($sy - $yn)) % $N;
                        my $x_sum = ($L * $L - $xn - $sx) % $N;

                        $yn = ($L * ($xn - $x_sum) - $yn) % $N;
                        $xn = $x_sum;
                    }
                }

                my $d = gcd(2 * $sy, $N);

                if ($d > 1) {
                    $d == $N ? last : return $d;
                }

                my $u = invmod(2 * $sy, $N);
                my $L = ($u * (3 * $sx * $sx + $z)) % $N;
                my $x2 = ($L * $L - 2 * $sx) % $N;

                $sy = ($L * ($sx - $x2) - $sy) % $N;
                $sx = $x2;

                $t >>= 1;
            }
            ($x, $y) = ($xn, $yn);
        }
    }

    return $N;    # failed
}

say ecm(14304849576137459);
say ecm(ipow(2, 128) + 1);    # takes ~11 seconds
