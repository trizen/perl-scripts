#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 05 March 2023
# https://github.com/trizen

# Generate all the Carmichael numbers with n prime factors in a given range [A,B] that are also strong Fermat pseudoprimes to a given base. (not in sorted order)

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

=for comment

# PARI/GP program:

carmichael_strong_psp(A, B, k, base) = A=max(A, vecprod(primes(k+1))\2); (f(m, l, p, k, k_exp, congr, u=0, v=0) = my(list=List()); if(k==1, forprime(q=u, v, my(t=m*q); if((t-1)%l == 0 && (t-1)%(q-1) == 0, my(tv=valuation(q-1, 2)); if(tv > k_exp && Mod(base, q)^(((q-1)>>tv)<<k_exp) == congr, listput(list, t)))), forprime(q = p, sqrtnint(B\m, k), if(base%q != 0, my(tv=valuation(q-1, 2)); if(tv > k_exp && Mod(base, q)^(((q-1)>>tv)<<k_exp) == congr, my(L=lcm(l, q-1)); if(gcd(L, m) == 1, my(t = m*q, u=ceil(A/t), v=B\t); if(u <= v, my(r=nextprime(q+1)); if(k==2 && r>u, u=r); list=concat(list, f(t, L, r, k-1, k_exp, congr, u, v)))))))); list); my(res=f(1, 1, 3, k, 0, 1)); for(v=0, logint(B, 2), res=concat(res, f(1, 1, 3, k, v, -1))); vecsort(Vec(res));

=cut

use 5.036;
use Math::GMPz;
use ntheory qw(:all);

sub carmichael_strong_fermat_in_range ($A, $B, $k, $base, $callback) {

    $A = vecmax($A, Math::GMPz->new(pn_primorial($k)));

    $A = Math::GMPz->new("$A");
    $B = Math::GMPz->new("$B");

    $A > $B and return;

    my $u = Math::GMPz::Rmpz_init();
    my $v = Math::GMPz::Rmpz_init();

    # max_p = floor((1 + sqrt(8*B + 1))/4)
    my $max_p = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_mul_2exp($max_p, $B, 3);
    Math::GMPz::Rmpz_add_ui($max_p, $max_p, 1);
    Math::GMPz::Rmpz_sqrt($max_p, $max_p);
    Math::GMPz::Rmpz_add_ui($max_p, $max_p, 1);
    Math::GMPz::Rmpz_div_2exp($max_p, $max_p, 2);
    $max_p = Math::GMPz::Rmpz_get_ui($max_p) if Math::GMPz::Rmpz_fits_ulong_p($max_p);

    my $generator = sub ($m, $L, $lo, $k, $k_exp, $congr) {

        Math::GMPz::Rmpz_tdiv_q($u, $B, $m);
        Math::GMPz::Rmpz_root($u, $u, $k);

        Math::GMPz::Rmpz_fits_ulong_p($u) || die "Too large value!";

        my $hi = Math::GMPz::Rmpz_get_ui($u);

        if ($lo > $hi) {
            return;
        }

        if ($k == 1) {

            $hi = $max_p if ($max_p < $hi);
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
                if (is_prime($p)) {
                    my $valuation = valuation($p - 1, 2);
                    if ($valuation > $k_exp and powmod($base, ($p - 1) >> ($valuation - $k_exp), $p) == ($congr % $p)) {
                        Math::GMPz::Rmpz_mul_ui($v, $m, $p);
                        Math::GMPz::Rmpz_sub_ui($u, $v, 1);
                        if (Math::GMPz::Rmpz_divisible_ui_p($u, $p - 1)) {
                            my $value = Math::GMPz::Rmpz_init_set($v);
                            $callback->($value);
                        }
                    }
                }
            }

            return;
        }

        my $z   = Math::GMPz::Rmpz_init();
        my $lcm = Math::GMPz::Rmpz_init();

        foreach my $p (@{primes($lo, $hi)}) {

            $base % $p == 0 and next;
            Math::GMPz::Rmpz_gcd_ui($Math::GMPz::NULL, $m, $p - 1) == 1 or next;

            my $valuation = valuation($p - 1, 2);
            $valuation > $k_exp                                                   or next;
            powmod($base, ($p - 1) >> ($valuation - $k_exp), $p) == ($congr % $p) or next;

            Math::GMPz::Rmpz_mul_ui($z, $m, $p);
            Math::GMPz::Rmpz_lcm_ui($lcm, $L, $p - 1);

            __SUB__->($z, $lcm, $p + 1, $k - 1, $k_exp, $congr);
        }
    };

    # Cases where 2^(d * 2^v) == -1 (mod p), for some v >= 0.
    foreach my $v (0 .. logint($B, 2)) {
        $generator->(Math::GMPz->new(1), Math::GMPz->new(1), 2, $k, $v, -1);
    }

    # Case where 2^d == 1 (mod p), where d is the odd part of p-1.
    $generator->(Math::GMPz->new(1), Math::GMPz->new(1), 2, $k, 0, 1);
}

# Generate all the 3-Carmichael numbers in the range [1, 10^8] that are also strong pseudoprimes to base 2.

my $k    = 3;
my $base = 2;
my $from = 1;
my $upto = 1e8;

my @arr;
carmichael_strong_fermat_in_range($from, $upto, $k, $base, sub ($n) { push @arr, $n });

say join(', ', sort { $a <=> $b } @arr);

__END__
15841, 29341, 52633, 252601, 314821, 1909001, 3581761, 4335241, 5049001, 5444489, 15247621, 29111881, 35703361, 36765901, 53711113, 68154001, 99036001
