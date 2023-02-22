#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 24 September 2022
# https://github.com/trizen

# Generate all the Carmichael numbers with n prime factors in a given range [A,B] that are also strong Fermat pseudoprimes to a given base. (not in sorted order)

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

=for comment

# PARI/GP program:
carmichael_strong_psp(A, B, k, base) = A=max(A, vecprod(primes(k+1))\2); (f(m, l, p, k, k_exp, congr, u=0, v=0) = my(list=List()); if(k==1, forprime(q=u, v, my(t=m*q); if((t-1)%l == 0 && (t-1)%(q-1) == 0, my(tv=valuation(q-1, 2)); if(tv > k_exp && Mod(base, q)^(((q-1)>>tv)<<k_exp) == congr, listput(list, t)))), forprime(q = p, sqrtnint(B\m, k), if(base%q != 0, my(tv=valuation(q-1, 2)); if(tv > k_exp && Mod(base, q)^(((q-1)>>tv)<<k_exp) == congr, my(L=lcm(l, q-1)); if(gcd(L, m) == 1, my(t = m*q, u=ceil(A/t), v=B\t); if(u <= v, my(r=nextprime(q+1)); if(k==2 && r>u, u=r); list=concat(list, f(t, L, r, k-1, k_exp, congr, u, v)))))))); list); my(res=f(1, 1, 3, k, 0, 1)); for(v=0, logint(B, 2), res=concat(res, f(1, 1, 3, k, v, -1))); vecsort(Vec(res));

=cut

use 5.020;
use warnings;

use ntheory      qw(:all);
use experimental qw(signatures);

sub divceil ($x, $y) {    # ceil(x/y)
    my $q = divint($x, $y);
    ($q * $y == $x) ? $q : ($q + 1);
}

sub carmichael_strong_fermat_in_range ($A, $B, $k, $base, $callback) {

    $A = vecmax($A, pn_primorial($k + 1) >> 1);

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
                if (is_prime($p)) {
                    my $n = $m * $p;
                    if (($n - 1) % ($p - 1) == 0) {
                        my $valuation = valuation($p - 1, 2);
                        if ($valuation > $k_exp and powmod($base, ($p - 1) >> ($valuation - $k_exp), $p) == ($congr % $p)) {
                            $callback->($n);
                        }
                    }
                }
            }

            return;
        }

        foreach my $p (@{primes($lo, $hi)}) {

            gcd($m, $p - 1) == 1 or next;

            my $valuation = valuation($p - 1, 2);
            $valuation > $k_exp                                                   or next;
            powmod($base, ($p - 1) >> ($valuation - $k_exp), $p) == ($congr % $p) or next;

            # gcd($m*$p, euler_phi($m*$p)) == 1 or die "$m*$p: not cyclic";

            __SUB__->($m * $p, lcm($L, $p - 1), $p + 1, $k - 1, $k_exp, $congr);
        }
    };

    # Case where 2^d == 1 (mod p), where d is the odd part of p-1.
    $generator->(1, 1, 3, $k, 0, 1);

    # Cases where 2^(d * 2^v) == -1 (mod p), for some v >= 0.
    foreach my $v (0 .. logint($B, 2)) {
        $generator->(1, 1, 3, $k, $v, -1);
    }
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
