#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 24 September 2022
# https://github.com/trizen

# Generate all the squarefree strong Fermat pseudoprimes to a given base with n prime factors in a given range [A,B]. (not in sorted order)

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

use 5.020;
use warnings;

use ntheory      qw(:all);
use experimental qw(signatures);

sub divceil ($x, $y) {    # ceil(x/y)
    (($x % $y == 0) ? 0 : 1) + divint($x, $y);
}

sub squarefree_strong_fermat_pseudoprimes_in_range ($A, $B, $k, $base, $callback) {

    $A = vecmax($A, pn_primorial($k));

    if ($A > $B) {
        return;
    }

    my $generator = sub ($m, $L, $lo, $k, $k_exp, $congr) {

        my $hi = rootint(divint($B, $m), $k);

        if ($lo > $hi) {
            return;
        }

        if ($k == 1) {

            $lo = vecmax($lo, divceil($A, $m));
            $lo > $hi && return;

            my $t = invmod($m, $L);
            $t > $hi && return;
            $t += $L while ($t < $lo);

            for (my $p = $t ; $p <= $hi ; $p += $L) {

                is_prime($p) || next;
                $base % $p == 0 and next;

                my $val = valuation($p - 1, 2);
                if ($val > $k_exp and powmod($base, ($p - 1) >> ($val - $k_exp), $p) == ($congr % $p)) {
                    my $n = $m * $p;
                    if (($n - 1) % znorder($base, $p) == 0) {
                        $callback->($n);
                    }
                }
            }

            return;
        }

        foreach my $p (@{primes($lo, $hi)}) {

            $base % $p == 0 and next;

            my $val = valuation($p - 1, 2);
            $val > $k_exp                                                   or next;
            powmod($base, ($p - 1) >> ($val - $k_exp), $p) == ($congr % $p) or next;

            my $z = znorder($base, $p);
            gcd($m, $z) == 1 or next;

            __SUB__->($m * $p, lcm($L, $z), $p + 1, $k - 1, $k_exp, $congr);
        }
    };

    # Case where 2^d == 1 (mod p), where d is the odd part of p-1.
    $generator->(1, 1, 2, $k, 0, 1);

    # Cases where 2^(d * 2^v) == -1 (mod p), for some v >= 0.
    foreach my $v (0 .. logint($B, 2)) {
        $generator->(1, 1, 2, $k, $v, -1);
    }
}

# Generate all the squarefree strong Fermat pseudoprimes to base 2 with 3 prime factors in the range [1, 10^8]

my $k    = 3;
my $base = 2;
my $from = 1;
my $upto = 1e8;

my @arr;
squarefree_strong_fermat_pseudoprimes_in_range($from, $upto, $k, $base, sub ($n) { push @arr, $n });

say join(', ', sort { $a <=> $b } @arr);

__END__
15841, 29341, 52633, 74665, 252601, 314821, 476971, 635401, 1004653, 1023121, 1907851, 1909001, 2419385, 2953711, 3581761, 4335241, 4682833, 5049001, 5444489, 5599765, 5681809, 9069229, 13421773, 15247621, 15510041, 15603391, 17509501, 26254801, 26758057, 27966709, 29111881, 35703361, 36765901, 37769887, 38342071, 44963029, 47349373, 47759041, 53399449, 53711113, 54468001, 60155201, 61377109, 61755751, 66977281, 68154001, 70030501, 71572957, 74329399, 82273201, 91659283, 99036001
