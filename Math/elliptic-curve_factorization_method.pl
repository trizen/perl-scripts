#!/usr/bin/perl

# The elliptic-curve factorization method (ECM), due to Hendrik Lenstra.

# Algorithm presented in the bellow video:
#   https://www.youtube.com/watch?v=2JlpeQWtGH8

# See also:
#   https://en.wikipedia.org/wiki/Lenstra_elliptic-curve_factorization

use 5.020;
use strict;
use warnings;

use Math::GMPz qw();
use experimental qw(signatures);
use ntheory qw(is_prime_power logint gcd);
use Math::Prime::Util::GMP qw(primes invmod);

sub ecm ($N, $zrange = 100, $plimit = 10000) {

    if (is_prime_power($N, \my $p)) {
        return $p;
    }

    my @primes = @{primes($plimit)};

    foreach my $z (-$zrange .. $zrange) {

        my $x = 0;
        my $y = 1;

        foreach my $p (@primes) {
            my $k = $p**logint($plimit, $p);

            my ($xn, $yn);
            my ($sx, $sy, $t) = ($x, $y, $k);

            my $first = 1;

            while ($t) {

                if ($t&1) {
                    if ($first) {
                        ($xn, $yn) = ($sx, $sy);
                        $first = 0;
                    }
                    else {
                        my $u = invmod($sx - $xn, $N);

                        if (not defined $u) {
                            my $d = gcd($sx - $xn, $N);
                            $d == $N ? last : return $d;
                        }

                        $u = Math::GMPz->new($u);

                        my $L = ($u * ($sy - $yn)) % $N;
                        my $xs = ($L * $L - $xn - $sx) % $N;

                        $yn = ($L * ($xn - $xs) - $yn) % $N;
                        $xn = $xs;
                    }
                }

                my $u = invmod(2 * $sy, $N);

                if (not defined $u) {
                    my $d = gcd(2 * $sy, $N);
                    $d == $N ? last : return $d;
                }

                $u = Math::GMPz->new($u);

                my $L = ($u * (3 * $sx * $sx + $z)) % $N;
                my $x2 = ($L * $L - 2 * $sx) % $N;

                $sy = ($L * ($sx - $x2) - $sy) % $N;
                $sx = $x2;

                $sy || return $N;

                $t >>= 1;
            }
            ($x, $y) = ($xn, $yn);
        }
    }

    return $N;    # failed
}

say ecm(Math::GMPz->new("14304849576137459"));
say ecm(79710615566344993);
say ecm(Math::GMPz->new(2)**128 + 1);    # takes ~3.4 seconds
