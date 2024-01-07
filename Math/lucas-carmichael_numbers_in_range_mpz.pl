#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 23 February 2023
# https://github.com/trizen

# Generate all the Lucas-Carmichael numbers with n prime factors in a given range [a,b]. (not in sorted order)

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

# PARI/GP program (up to n):
#   upto(n, k) = my(A=vecprod(primes(k+1))\2, B=n); (f(m, l, p, k, u=0, v=0) = my(list=List()); if(k==1, forprime(p=u, v, my(t=m*p); if((t+1)%l == 0 && (t+1)%(p+1) == 0, listput(list, t))), forprime(q = p, sqrtnint(B\m, k), my(t = m*q); my(L=lcm(l, q+1)); if(gcd(L, t) == 1, my(u=ceil(A/t), v=B\t); if(u <= v, my(r=nextprime(q+1)); if(k==2 && r>u, u=r); list=concat(list, f(t, L, r, k-1, u, v)))))); list); vecsort(Vec(f(1, 1, 3, k)));

# PARI/GP program (in range [A, B]):
#   lucas_carmichael(A, B, k) = A=max(A, vecprod(primes(k+1))\2); (f(m, l, lo, k) = my(list=List()); my(hi=sqrtnint(B\m, k)); if(lo > hi, return(list)); if(k==1, lo=max(lo, ceil(A/m)); my(t=lift(-1/Mod(m,l))); while(t < lo, t += l); forstep(p=t, hi, l, if(isprime(p), my(n=m*p); if((n+1)%(p+1) == 0, listput(list, n)))), forprime(p=lo, hi, if(gcd(m, p+1) == 1, list=concat(list, f(m*p, lcm(l, p+1), p+1, k-1))))); list); vecsort(Vec(f(1, 1, 3, k)));

use 5.036;
use Math::GMPz;
use ntheory qw(:all);

sub divceil ($x, $y) {    # ceil(x/y)
    (($x % $y == 0) ? 0 : 1) + divint($x, $y);
}

sub lucas_carmichael_numbers_in_range ($A, $B, $k) {

    $A = vecmax($A, pn_primorial($k + 1) >> 1);

    $A = Math::GMPz->new("$A");
    $B = Math::GMPz->new("$B");

    my $u = Math::GMPz::Rmpz_init();
    my $v = Math::GMPz::Rmpz_init();

    # max_p = floor(sqrt(B))
    my $max_p = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_sqrt($max_p, $B);
    $max_p = Math::GMPz::Rmpz_get_ui($max_p) if Math::GMPz::Rmpz_fits_ulong_p($max_p);

    my @list;

    sub ($m, $L, $lo, $k) {

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
            Math::GMPz::Rmpz_sub($v, $L, $v);

            if (Math::GMPz::Rmpz_cmp_ui($v, $hi) > 0) {
                return;
            }

            if (Math::GMPz::Rmpz_fits_ulong_p($L)) {
                $L = Math::GMPz::Rmpz_get_ui($L);
            }

            my $t = Math::GMPz::Rmpz_get_ui($v);
            $t > $hi && return;
            $t += $L * divceil($lo - $t, $L) if ($t < $lo);

            for (my $p = $t ; $p <= $hi ; $p += $L) {
                if (is_prime($p)) {
                    Math::GMPz::Rmpz_mul_ui($v, $m, $p);
                    Math::GMPz::Rmpz_add_ui($u, $v, 1);
                    if (Math::GMPz::Rmpz_divisible_ui_p($u, $p + 1)) {
                        push @list, Math::GMPz::Rmpz_init_set($v);
                    }
                }
            }

            return;
        }

        my $z   = Math::GMPz::Rmpz_init();
        my $lcm = Math::GMPz::Rmpz_init();

        foreach my $p (@{primes($lo, $hi)}) {

            Math::GMPz::Rmpz_gcd_ui($Math::GMPz::NULL, $m, $p + 1) == 1 or next;
            Math::GMPz::Rmpz_lcm_ui($lcm, $L, $p + 1);
            Math::GMPz::Rmpz_mul_ui($z, $m, $p);

            __SUB__->($z, $lcm, $p + 1, $k - 1);
        }
      }
      ->(Math::GMPz->new(1), Math::GMPz->new(1), 3, $k);

    return sort { $a <=> $b } @list;
}

# Generate all the Lucas-Carmichael numbers with 5 prime factors in the range [100, 10^8]

my $k    = 5;
my $from = 100;
my $upto = 1e8;

my @arr = lucas_carmichael_numbers_in_range($from, $upto, $k);
say join(', ', @arr);

__END__
588455, 1010735, 2276351, 2756159, 4107455, 4874639, 5669279, 6539819, 8421335, 13670855, 16184663, 16868159, 21408695, 23176439, 24685199, 25111295, 26636687, 30071327, 34347599, 34541639, 36149399, 36485015, 38999519, 39715319, 42624911, 43134959, 49412285, 49591919, 54408959, 54958799, 57872555, 57953951, 64456223, 66709019, 73019135, 77350559, 78402815, 82144799, 83618639, 86450399, 93277079, 96080039, 98803439
