#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 22 February 2023
# Edit: 09 March 2026
# https://github.com/trizen

# Generate all the Carmichael numbers with n prime factors in a given range [a,b].

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

# PARI/GP program (in range) (simple):
#   carmichael(A, B, k) = A=max(A, vecprod(primes(k+1))\2); (f(m, l, lo, k) = my(list=List()); my(hi=sqrtnint(B\m, k)); if(k==1, forprime(p=max(lo, ceil(A/m)), hi, my(t=m*p); if((t-1)%l == 0 && (t-1)%(p-1) == 0, listput(list, t))), forprime(p = lo, hi, my(t = m*p); my(L=lcm(l, p-1)); if(gcd(L, t) == 1, list=concat(list, f(t, L, p+1, k-1))))); list); vecsort(Vec(f(1, 1, 3, k)));

# PARI/GP program (in range) (faster):
#   carmichael(A, B, k) = A=max(A, vecprod(primes(k+1))\2); local f; (f = (m, l, lo, k) -> my(list=List()); my(hi=sqrtnint(B\m, k)); if(lo > hi, return(list)); if(k==1, lo=max(lo, ceil(A/m)); my(t=lift(1/Mod(m,l))); while(t < lo, t += l); forstep(p=t, hi, l, if((m*p-1)%(p-1) == 0 && isprime(p), listput(list, m*p))), forprime(p=lo, hi, if(gcd(m, p-1) == 1, list=concat(list, f(m*p, lcm(l, p-1), p+1, k-1))))); list); vecsort(Vec(f(1, 1, 3, k)));

use 5.036;
use Math::GMPz;
use ntheory 0.74 qw(:all);

sub carmichael_numbers_in_range ($A, $B, $k) {

    $A = vecmax($A, pn_primorial($k + 1) >> 1);

    $A = Math::GMPz->new("$A");
    $B = Math::GMPz->new("$B");

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

    my @list;

    sub ($m, $L, $lo, $k) {

        Math::GMPz::Rmpz_tdiv_q($u, $B, $m);
        Math::GMPz::Rmpz_root($u, $u, $k);

        Math::GMPz::Rmpz_fits_ulong_p($u) || die "Too large value!";

        my $hi = Math::GMPz::Rmpz_get_ui($u);

        $lo > $hi && return;

        # Pinch's bound for the second to last prime
        if ($k == 2 and Math::GMPz::Rmpz_cmp_ui($m, 1_000) <= 0) {
            my $m_ui  = Math::GMPz::Rmpz_get_ui($m);
            my $bound = 2 * $m_ui * $m_ui - 3 * $m_ui + 2;
            if ($hi > $bound) {
                $hi = $bound;
                $lo > $hi && return;
            }
        }

        if ($k == 1) {

            $hi = $max_p                      if ($max_p < $hi);
            $hi = Math::GMPz::Rmpz_get_ui($m) if (Math::GMPz::Rmpz_cmp_ui($m, $hi) < 0);
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

            my $inv_m = $t;
            $t += $L * cdivint($lo - $t, $L) if ($t < $lo);
            $t > $hi && return;

            for (my $p = $t ; $p <= $hi ; $p += $L) {
                if (is_prime($p)) {
                    Math::GMPz::Rmpz_mul_ui($v, $m, $p);
                    Math::GMPz::Rmpz_sub_ui($u, $v, 1);
                    if (Math::GMPz::Rmpz_divisible_ui_p($u, $p - 1)) {
                        push @list, Math::GMPz::Rmpz_init_set($v);
                    }
                }
            }

            return;
        }

        my $z   = Math::GMPz::Rmpz_init();
        my $lcm = Math::GMPz::Rmpz_init();

        foreach my $p (@{primes($lo, $hi)}) {

            Math::GMPz::Rmpz_gcd_ui($Math::GMPz::NULL, $m, $p >> 1) == 1 or next;
            Math::GMPz::Rmpz_lcm_ui($lcm, $L, $p - 1);
            Math::GMPz::Rmpz_mul_ui($z, $m, $p);

            __SUB__->($z, $lcm, $p + 1, $k - 1);
        }
      }
      ->(Math::GMPz->new(1), Math::GMPz->new(1), 3, $k);

    return sort { $a <=> $b } @list;
}

my $from = 1;
my $upto = powint(10, 10);

foreach my $k (3 .. 7) {
    my @arr = carmichael_numbers_in_range($from, $upto, $k);
    say "There are: ", scalar(@arr), " Carmichael numbers <= $upto with $k prime factors";
}

__END__
There are: 335 Carmichael numbers <= 10000000000 with 3 prime factors
There are: 619 Carmichael numbers <= 10000000000 with 4 prime factors
There are: 492 Carmichael numbers <= 10000000000 with 5 prime factors
There are: 99 Carmichael numbers <= 10000000000 with 6 prime factors
There are: 2 Carmichael numbers <= 10000000000 with 7 prime factors
