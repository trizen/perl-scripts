#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 28 June 2020
# https://github.com/trizen

# A simple factorization method, using quadratic integers.
# Similar in flavor to Pollard's p-1 and Williams's p+1 methods.

# See also:
#   https://en.wikipedia.org/wiki/Quadratic_integer

use 5.020;
use warnings;

use ntheory qw(primes);
use experimental qw(signatures);
use Math::AnyNum qw(:overload gcd ilog isqrt);

sub quadratic_powmod ($a, $b, $w, $n, $m) {

    my ($x, $y) = (1, 0);

    do {
        ($x, $y) = (($a * $x + $b * $y * $w) % $m, ($a * $y + $b * $x) % $m) if ($n & 1);
        ($a, $b) = (($a * $a + $b * $b * $w) % $m, (2 * $a * $b) % $m);
    } while ($n >>= 1);

    ($x, $y);
}

sub quadratic_factorization ($n, $B, $a = 3, $b = 4, $w = 2) {

    foreach my $p (@{primes(isqrt($B))}) {
        ($a, $b) = quadratic_powmod($a, $b, $w, $p**ilog($B, $p), $n);
    }

    foreach my $p (@{primes(isqrt($B) + 1, $B)}) {

        ($a, $b) = quadratic_powmod($a, $b, $w, $p, $n);

        my $g = gcd($b, $n);

        if ($g > 1) {
            return 1 if ($g == $n);
            return $g;
        }
    }

    return 1;
}

say quadratic_factorization(2**64 + 1, 20, 9, 2, 4);                 #=> 274177           (p-1 is   20-smooth)
say quadratic_factorization(257221 * 470783,               1000);    #=> 470783           (p-1 is 1000-smooth)
say quadratic_factorization(1124075136413 * 3556516507813, 4000);    #=> 1124075136413    (p+1 is 4000-smooth)
say quadratic_factorization(7553377229 * 588103349,        800);     #=> 7553377229       (p+1 is  800-smooth)

say '';

say quadratic_factorization(333732865481 * 1632480277613, 3000);     #=> 333732865481     (p-1 is 3000-smooth)
say quadratic_factorization(15597344393 * 12388291753,    3000);     #=> 15597344393      (p-1 is 3000-smooth)
say quadratic_factorization(43759958467 * 59037829639,    3200);     #=> 43759958467      (p+1 is 3200-smooth)
say quadratic_factorization(112601635303 * 83979783007,   700);      #=> 112601635303     (p-1 is  700-smooth)
say quadratic_factorization(228640480273 * 224774973299,  2000);     #=> 228640480273     (p-1 is 2000-smooth)

say '';

say quadratic_factorization(5140059121 * 8382882743,     2500);            #=> 5140059121       (p-1 is 2500-smooth)
say quadratic_factorization(18114813019 * 17402508649,   6000);            #=> 18114813019      (p+1 is 6000-smooth)
say quadratic_factorization(533091092393 * 440050095029, 300, 1, 2, 3);    #=> 533091092393     (p+1 is  300-smooth)
