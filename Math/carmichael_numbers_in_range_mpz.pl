#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 22 February 2023
# https://github.com/trizen

# Generate all the Carmichael numbers with n prime factors in a given range [a,b]. (not in sorted order)

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

# PARI/GP program (in range) (simple):
#   carmichael(A, B, k) = A=max(A, vecprod(primes(k+1))\2); (f(m, l, lo, k) = my(list=List()); my(hi=sqrtnint(B\m, k)); if(k==1, forprime(p=max(lo, ceil(A/m)), hi, my(t=m*p); if((t-1)%l == 0 && (t-1)%(p-1) == 0, listput(list, t))), forprime(p = lo, hi, my(t = m*p); my(L=lcm(l, p-1)); if(gcd(L, t) == 1, list=concat(list, f(t, L, p+1, k-1))))); list); vecsort(Vec(f(1, 1, 3, k)));

# PARI/GP program (in range) (faster):
#   carmichael(A, B, k) = A=max(A, vecprod(primes(k+1))\2); (f(m, l, lo, k) = my(list=List()); my(hi=sqrtnint(B\m, k)); if(lo > hi, return(list)); if(k==1, lo=max(lo, ceil(A/m)); my(t=lift(1/Mod(m,l))); while(t < lo, t += l); forstep(p=t, hi, l, if(isprime(p), my(n=m*p); if((n-1)%(p-1) == 0, listput(list, n)))), forprime(p=lo, hi, if(gcd(m, p-1) == 1, list=concat(list, f(m*p, lcm(l, p-1), p+1, k-1))))); list); vecsort(Vec(f(1, 1, 3, k)));

use 5.036;
use Math::GMPz;
use ntheory qw(:all);

sub carmichael_numbers_in_range ($A, $B, $k, $callback) {

    $A = vecmax($A, pn_primorial($k + 1) >> 1);

    $A = Math::GMPz->new("$A");
    $B = Math::GMPz->new("$B");

    my $u = Math::GMPz::Rmpz_init();
    my $v = Math::GMPz::Rmpz_init();

    sub ($m, $L, $lo, $k) {

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
                if (is_prime($p)) {
                    Math::GMPz::Rmpz_mul_ui($v, $m, $p);
                    Math::GMPz::Rmpz_sub_ui($u, $v, 1);
                    if (Math::GMPz::Rmpz_divisible_ui_p($u, $p - 1)) {
                        $callback->(Math::GMPz::Rmpz_init_set($v));
                    }
                }
            }

            return;
        }

        my $z   = Math::GMPz::Rmpz_init();
        my $lcm = Math::GMPz::Rmpz_init();

        foreach my $p (@{primes($lo, $hi)}) {

            Math::GMPz::Rmpz_gcd_ui($Math::GMPz::NULL, $m, $p - 1) == 1 or next;
            Math::GMPz::Rmpz_lcm_ui($lcm, $L, $p - 1);
            Math::GMPz::Rmpz_mul_ui($z, $m, $p);

            __SUB__->($z, $lcm, $p + 1, $k - 1);
        }
      }
      ->(Math::GMPz->new(1), Math::GMPz->new(1), 3, $k);
}

# Generate all the 5-Carmichael numbers in the range [100, 10^8]

my $k    = 5;
my $from = 100;
my $upto = 1e8;

my @arr;
carmichael_numbers_in_range($from, $upto, $k, sub ($n) { push @arr, $n });

say join(', ', sort { $a <=> $b } @arr);

__END__
825265, 1050985, 9890881, 10877581, 12945745, 13992265, 16778881, 18162001, 27336673, 28787185, 31146661, 36121345, 37167361, 40280065, 41298985, 41341321, 41471521, 47006785, 67371265, 67994641, 69331969, 74165065, 75151441, 76595761, 88689601, 93614521, 93869665
