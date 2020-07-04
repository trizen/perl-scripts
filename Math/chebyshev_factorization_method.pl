#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 23 January 2020
# https://github.com/trizen

# A simple factorization method, using the Chebyshev T_n(x) polynomials, based on the identity:
#   T_{m n}(x) = T_m(T_n(x))

# where:
#   T_n(x) = (1/2) * V_n(2x, 1)

# where V_n(P, Q) is the Lucas V sequence.

# See also:
#   https://oeis.org/A001075
#   https://en.wikipedia.org/wiki/Lucas_sequence
#   https://en.wikipedia.org/wiki/Iterated_function
#   https://en.wikipedia.org/wiki/Chebyshev_polynomials

use 5.020;
use warnings;
use experimental qw(signatures);
use Math::AnyNum qw(:overload lucasVmod gcd next_prime invmod ilog);

sub chebyshev_factorization ($n, $B = ilog($n, 2)**2, $a = 127) {

    my $x = $a;
    my $G = $B * $B;
    my $i = invmod(2, $n);

    my sub chebyshevTmod ($a, $x) {
        (lucasVmod(2 * $x, 1, $a, $n) * $i) % $n;
    }

    for (my $p = 2 ; $p <= $B ; $p = next_prime($p)) {
        $x = chebyshevTmod($p**ilog($G, $p), $x);    # T_k(x) (mod n)
        my $g = gcd($x - 1, $n);
        return $g if ($g > 1);
    }

    return 1;
}

say chebyshev_factorization(2**64 + 1,                     20);      #=> 274177           (p-1 is   20-smooth)
say chebyshev_factorization(257221 * 470783,               1000);    #=> 470783           (p-1 is 1000-smooth)
say chebyshev_factorization(1124075136413 * 3556516507813, 4000);    #=> 1124075136413    (p+1 is 4000-smooth)
say chebyshev_factorization(7553377229 * 588103349,        800);     #=> 7553377229       (p+1 is  800-smooth)

say '';

say chebyshev_factorization(333732865481 * 1632480277613, 3000);     #=> 333732865481     (p-1 is 3000-smooth)
say chebyshev_factorization(15597344393 * 12388291753,    3000);     #=> 15597344393      (p-1 is 3000-smooth)
say chebyshev_factorization(43759958467 * 59037829639,    3200);     #=> 43759958467      (p+1 is 3200-smooth)
say chebyshev_factorization(112601635303 * 83979783007,   700);      #=> 112601635303     (p-1 is  700-smooth)
say chebyshev_factorization(228640480273 * 224774973299,  2000);     #=> 228640480273     (p-1 is 2000-smooth)

say '';

say chebyshev_factorization(5140059121 * 8382882743,     2500);      #=> 5140059121       (p-1 is 2500-smooth)
say chebyshev_factorization(18114813019 * 17402508649,   6000);      #=> 18114813019      (p+1 is 6000-smooth)
say chebyshev_factorization(533091092393 * 440050095029, 300);       #=> 533091092393     (p+1 is  300-smooth)
