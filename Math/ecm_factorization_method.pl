#!/usr/bin/perl

# The elliptic-curve factorization method (ECM), due to Hendrik Lenstra.

# Algorithm presented in the YouTube video:
#   https://www.youtube.com/watch?v=2JlpeQWtGH8

# See also:
#   https://en.wikipedia.org/wiki/Lenstra_elliptic-curve_factorization

use 5.020;
use strict;
use warnings;

use Math::GMPz qw();
use experimental qw(signatures);
use ntheory qw(is_prime_power logint);
use Math::Prime::Util::GMP qw(primes vecprod random_nbit_prime);

sub ecm ($N, $zrange = 200, $plimit = 20000) {

    # Check for perfect powers
    if (is_prime_power($N, \my $p)) {
        return $p;
    }

    # Make sure `N` is a Math::GMPz object
    if (ref($N) ne 'Math::GMPz') {
        $N = Math::GMPz->new("$N");
    }

    # Primes up to `plimit`
    my @primes = @{primes($plimit)};

    # Temporary mpz objects
    my $t  = Math::GMPz::Rmpz_init();
    my $t1 = Math::GMPz::Rmpz_init();
    my $t2 = Math::GMPz::Rmpz_init();

    foreach my $z (-$zrange .. $zrange) {

        my $x = Math::GMPz::Rmpz_init_set_ui(0);
        my $y = Math::GMPz::Rmpz_init_set_ui(1);

        foreach my $p (@primes) {

            my ($xn, $yn);
            my ($sx, $sy, $k) = ($x, $y, $p**logint($plimit, $p));

            my $first = 1;

            while ($k) {

                if ($k & 1) {

                    if ($first) {
                        ($xn, $yn) = ($sx, $sy);
                        $first = 0;
                    }
                    else {
                        Math::GMPz::Rmpz_sub($t, $sx, $xn);

                        if (!Math::GMPz::Rmpz_invert($t2, $t, $N)) {
                            Math::GMPz::Rmpz_gcd($t2, $t, $N);
                            Math::GMPz::Rmpz_cmp($t2, $N) ? return $t2 : last;
                        }

                        my $u = $t2;

                        # u * (sy - yn)
                        Math::GMPz::Rmpz_sub($t, $sy, $yn);
                        Math::GMPz::Rmpz_mul($t, $t, $u);
                        Math::GMPz::Rmpz_mod($t2, $t, $N);

                        my $L = $t2;

                        # L^2 - xn - sx
                        Math::GMPz::Rmpz_mul($t, $L, $L);
                        Math::GMPz::Rmpz_sub($t, $t, $xn);
                        Math::GMPz::Rmpz_sub($t, $t, $sx);
                        Math::GMPz::Rmpz_mod($t, $t, $N);

                        my $x_sum = Math::GMPz::Rmpz_init_set($t);

                        Math::GMPz::Rmpz_sub($t, $xn, $x_sum);
                        Math::GMPz::Rmpz_mul($t, $t, $L);
                        Math::GMPz::Rmpz_sub($t, $t, $yn);
                        Math::GMPz::Rmpz_mod($t, $t, $N);

                        $yn = Math::GMPz::Rmpz_init_set($t);
                        $xn = $x_sum;
                    }
                }

                Math::GMPz::Rmpz_mul_2exp($t, $sy, 1);

                if (!Math::GMPz::Rmpz_invert($t2, $t, $N)) {
                    Math::GMPz::Rmpz_gcd($t2, $t, $N);
                    Math::GMPz::Rmpz_cmp($t2, $N) ? return $t2 : last;
                }

                my $u = $t2;

                # u * (3 * sx^2 + z) % N
                Math::GMPz::Rmpz_mul($t, $sx, $sx);
                Math::GMPz::Rmpz_mul_ui($t, $t, 3);

                $z < 0
                  ? Math::GMPz::Rmpz_sub_ui($t, $t, -$z)
                  : Math::GMPz::Rmpz_add_ui($t, $t, $z);

                Math::GMPz::Rmpz_mul($t, $t, $u);
                Math::GMPz::Rmpz_mod($t2, $t, $N);

                my $L = $t2;

                # (L*L - 2*sx) % N
                Math::GMPz::Rmpz_mul($t, $L, $L);
                Math::GMPz::Rmpz_submul_ui($t, $sx, 2);
                Math::GMPz::Rmpz_mod($t, $t, $N);

                my $x2 = Math::GMPz::Rmpz_init_set($t);

                # (L * (sx - x2) - sy) % N
                Math::GMPz::Rmpz_sub($t, $sx, $x2);
                Math::GMPz::Rmpz_mul($t, $t, $L);
                Math::GMPz::Rmpz_sub($t, $t, $sy);
                Math::GMPz::Rmpz_mod($t, $t, $N);

                $sy = Math::GMPz::Rmpz_init_set($t);
                $sx = $x2;

                # Failure when t = 0
                return $N if !Math::GMPz::Rmpz_sgn($t);

                $k >>= 1;
            }

            ($x, $y) = ($xn, $yn);
        }
    }

    return $N;    # failed to factorize N
}

# Factoring the 7th Fermat numebr: 2^128 + 1
say ecm(Math::GMPz->new(2)**128 + 1, 100, 8000);    # takes ~1 second

say "\n=> More tests:";

foreach my $k (10 .. 40) {

    my $n = Math::GMPz->new(vecprod(map { random_nbit_prime($k) } 1 .. 2));
    my $p = ecm($n, logint($n, 2), logint($n, 2)**2);

    if ($p > 1 and $p < $n) {
        say "$n = $p * ", $n / $p;
    }
    else {
        say "Failed to factor $n";
    }
}
