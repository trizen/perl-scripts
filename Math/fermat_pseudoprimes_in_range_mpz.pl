#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 25 February 2023
# https://github.com/trizen

# Generate all the k-omega Fermat pseudoprimes in range [a,b]. (not in sorted order)

# Definition:
#   k-omega primes are numbers n such that omega(n) = k.

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://en.wikipedia.org/wiki/Prime_omega_function
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

# PARI/GP program (version 1):
#   fermat_psp(A, B, k, base=2) = A=max(A, vecprod(primes(k))); (f(m, l, p, j) = my(list=List()); forprime(q=p, sqrtnint(B\m, j), if(base%q != 0, my(z=znorder(Mod(base, q)), L=lcm(l, z)); if(gcd(L, m)==1, my(v=m*q, r=nextprime(q+1)); while(v <= B, if(j==1, if(v>=A && if(k==1, !isprime(v), 1) && (v-1)%l == 0 && (v-1)%z == 0 && Mod(base, v)^(v-1) == 1, listput(list, v)), if(v*r <= B, list=concat(list, f(v, l, r, j-1)))); v *= q)))); list); vecsort(Vec(f(1, 1, 2, k)));

# PARI/GP program (version 2):
#   fermat_psp(A, B, k, base) = A=max(A, vecprod(primes(k))); (f(m, l, p, j) = my(list=List()); forprime(q=p, sqrtnint(B\m, j), if(base%q != 0, my(v=m*q, t=q, r=nextprime(q+1)); while(v <= B, my(L=lcm(l, znorder(Mod(base, t)))); if(gcd(L, v) == 1, if(j==1, if(v>=A && if(k==1, !isprime(v), 1) && (v-1)%L == 0, listput(list, v)), if(v*r <= B, list=concat(list, f(v, L, r, j-1)))), break); v *= q; t *= q))); list); vecsort(Vec(f(1, 1, 2, k)));

use 5.036;
use Math::GMPz;
use ntheory qw(:all);

sub fermat_pseudoprimes_in_range ($A, $B, $k, $base, $callback) {

    $A = vecmax($A, pn_primorial($k));

    $A = Math::GMPz->new("$A");
    $B = Math::GMPz->new("$B");

    my $u = Math::GMPz::Rmpz_init();
    my $v = Math::GMPz::Rmpz_init();
    my $w = Math::GMPz::Rmpz_init();

    sub ($m, $L, $lo, $j) {

        Math::GMPz::Rmpz_tdiv_q($u, $B, $m);
        Math::GMPz::Rmpz_root($u, $u, $j);

        my $hi = Math::GMPz::Rmpz_get_ui($u);

        if ($lo > $hi) {
            return;
        }

        if ($j == 1) {

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
                if (is_prime($p) and $base % $p != 0) {

                    Math::GMPz::Rmpz_set_ui($u, $p);
                    Math::GMPz::Rmpz_mul_ui($v, $m, $p);

                    while (Math::GMPz::Rmpz_cmp($v, $B) <= 0) {
                        if ($k == 1 and is_prime($v)) {
                            ## ok
                        }
                        elsif (Math::GMPz::Rmpz_cmp($v, $A) >= 0) {
                            Math::GMPz::Rmpz_sub_ui($w, $v, 1);
                            if ((ref($L) ? Math::GMPz::Rmpz_divisible_p($w, $L) : Math::GMPz::Rmpz_divisible_ui_p($w, $L))
                                and Math::GMPz::Rmpz_divisible_ui_p($w, znorder($base, $u))) {
                                $callback->(Math::GMPz::Rmpz_init_set($v));
                            }
                        }
                        Math::GMPz::Rmpz_mul_ui($u, $u, $p);
                        Math::GMPz::Rmpz_mul_ui($v, $v, $p);
                    }
                }
            }

            return;
        }

        my $u   = Math::GMPz::Rmpz_init();
        my $v   = Math::GMPz::Rmpz_init();
        my $lcm = Math::GMPz::Rmpz_init();

        foreach my $p (@{primes($lo, $hi)}) {

            $base % $p == 0 and next;

            Math::GMPz::Rmpz_set_ui($u, $p);
            Math::GMPz::Rmpz_mul_ui($v, $m, $p);

            while (Math::GMPz::Rmpz_cmp($v, $B) <= 0) {
                my $z = znorder($base, $u);
                Math::GMPz::Rmpz_gcd_ui($Math::GMPz::NULL, $v, $z) == 1 or last;
                Math::GMPz::Rmpz_lcm_ui($lcm, $L, $z);
                __SUB__->($v, $lcm, $p + 1, $j - 1);
                Math::GMPz::Rmpz_mul_ui($u, $u, $p);
                Math::GMPz::Rmpz_mul_ui($v, $v, $p);
            }
        }
      }
      ->(Math::GMPz->new(1), Math::GMPz->new(1), 2, $k);
}

# Generate all the Fermat pseudoprimes to base 3 in range [1, 10^5]

my $from = 1;
my $upto = 1e5;
my $base = 3;

my @arr;
foreach my $k (1 .. 100) {
    last if pn_primorial($k) > $upto;
    fermat_pseudoprimes_in_range($from, $upto, $k, $base, sub ($n) { push @arr, $n });
}

say join(', ', sort { $a <=> $b } @arr);

__END__
91, 121, 286, 671, 703, 949, 1105, 1541, 1729, 1891, 2465, 2665, 2701, 2821, 3281, 3367, 3751, 4961, 5551, 6601, 7381, 8401, 8911, 10585, 11011, 12403, 14383, 15203, 15457, 15841, 16471, 16531, 18721, 19345, 23521, 24046, 24661, 24727, 28009, 29161, 29341, 30857, 31621, 31697, 32791, 38503, 41041, 44287, 46657, 46999, 47197, 49051, 49141, 50881, 52633, 53131, 55261, 55969, 63139, 63973, 65485, 68887, 72041, 74593, 75361, 76627, 79003, 82513, 83333, 83665, 87913, 88561, 88573, 88831, 90751, 93961, 96139, 97567
