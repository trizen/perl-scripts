#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 25 February 2023
# https://github.com/trizen

# Generate all the squarefree strong Fermat pseudoprimes to a given base with n prime factors in a given range [A,B]. (not in sorted order)

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

use 5.036;
use Math::GMPz;
use ntheory qw(:all);

sub squarefree_strong_fermat_pseudoprimes_in_range ($A, $B, $k, $base, $callback) {

    $A = vecmax($A, pn_primorial($k));

    $A = Math::GMPz->new("$A");
    $B = Math::GMPz->new("$B");

    my $u = Math::GMPz::Rmpz_init();
    my $v = Math::GMPz::Rmpz_init();

    my $generator = sub ($m, $L, $lo, $k, $k_exp, $congr) {

        Math::GMPz::Rmpz_tdiv_q($u, $B, $m);
        Math::GMPz::Rmpz_root($u, $u, $k);

        my $hi = Math::GMPz::Rmpz_get_ui($u);

        if ($lo > $hi) {
            return;
        }

        if ($k == 1) {

            Math::GMPz::Rmpz_cdiv_q($u, $A, $m);

            if (Math::GMPz::Rmpz_fits_ulong_p($u)) {
                $lo = vecmax($lo, Math::GMPz::Rmpz_get_ui($u));
            }
            elsif (Math::GMPz::Rmpz_cmp_ui($u, $lo) > 0) {
                if (Math::GMPz::Rmpz_cmp_ui($u, $hi) > 0) {
                    return;
                }
                $lo = Math::GMPz::Rmpz_get_ui($u);
            }

            if ($lo > $hi) {
                return;
            }

            Math::GMPz::Rmpz_invert($v, $m, $L);

            if (Math::GMPz::Rmpz_cmp_ui($v, $hi) > 0) {
                return;
            }

            if (Math::GMPz::Rmpz_fits_ulong_p($L)) {
                $L = Math::GMPz::Rmpz_get_ui($L);
            }

            my $t = Math::GMPz::Rmpz_get_ui($v);
            $t > $hi && return;
            $t += $L while ($t < $lo);

            for (my $p = $t ; $p <= $hi ; $p += $L) {

                is_prime($p) || next;
                $base % $p == 0 and next;

                my $val = valuation($p - 1, 2);
                if ($val > $k_exp and powmod($base, ($p - 1) >> ($val - $k_exp), $p) == ($congr % $p)) {
                    Math::GMPz::Rmpz_mul_ui($v, $m, $p);
                    Math::GMPz::Rmpz_sub_ui($u, $v, 1);
                    if (Math::GMPz::Rmpz_divisible_ui_p($u, znorder($base, $p))) {
                        $callback->(Math::GMPz::Rmpz_init_set($v));
                    }
                }
            }

            return;
        }

        my $t   = Math::GMPz::Rmpz_init();
        my $lcm = Math::GMPz::Rmpz_init();

        foreach my $p (@{primes($lo, $hi)}) {

            $base % $p == 0 and next;

            my $val = valuation($p - 1, 2);
            $val > $k_exp                                                   or next;
            powmod($base, ($p - 1) >> ($val - $k_exp), $p) == ($congr % $p) or next;

            my $z = znorder($base, $p);
            Math::GMPz::Rmpz_gcd_ui($Math::GMPz::NULL, $m, $z) == 1 or next;
            Math::GMPz::Rmpz_lcm_ui($lcm, $L, $z);
            Math::GMPz::Rmpz_mul_ui($t, $m, $p);

            __SUB__->($t, $lcm, $p + 1, $k - 1, $k_exp, $congr);
        }
    };

    # Case where 2^d == 1 (mod p), where d is the odd part of p-1.
    $generator->(Math::GMPz->new(1), Math::GMPz->new(1), 2, $k, 0, 1);

    # Cases where 2^(d * 2^v) == -1 (mod p), for some v >= 0.
    foreach my $v (0 .. logint($B, 2)) {
        $generator->(Math::GMPz->new(1), Math::GMPz->new(1), 2, $k, $v, -1);
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
