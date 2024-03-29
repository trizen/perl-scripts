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

# PARI/GP program (slow):
#   fermat_psp(A, B, k, base) = A=max(A, vecprod(primes(k))); (f(m, l, p, j) = my(list=List()); forprime(q=p, sqrtnint(B\m, j), if(base%q != 0, my(v=m*q, t=q, r=nextprime(q+1)); while(v <= B, my(L=lcm(l, znorder(Mod(base, t)))); if(gcd(L, v) == 1, if(j==1, if(v>=A && if(k==1, !isprime(v), 1) && (v-1)%L == 0, listput(list, v)), if(v*r <= B, list=concat(list, f(v, L, r, j-1)))), break); v *= q; t *= q))); list); vecsort(Vec(f(1, 1, 2, k)));

# PARI/GP program (fast):
#   fermat_psp(A, B, k, base) = A=max(A, vecprod(primes(k))); (f(m, l, lo, k) = my(list=List()); my(hi=sqrtnint(B\m, k)); if(lo > hi, return(list)); if(k==1, forstep(p=lift(1/Mod(m, l)), hi, l, if(isprimepower(p) && gcd(m*base, p) == 1, my(n=m*p); if(n >= A && (n-1) % znorder(Mod(base, p)) == 0, listput(list, n)))), forprime(p=lo, hi, base%p == 0 && next; my(z=znorder(Mod(base, p))); gcd(m,z) == 1 || next; my(q=p, v=m*p); while(v <= B, list=concat(list, f(v, lcm(l, z), p+1, k-1)); q *= p; Mod(base, q)^z == 1 || break; v *= p))); list); vecsort(Set(f(1, 1, 2, k)));

use 5.036;
use Math::GMPz;
use ntheory qw(:all);

sub divceil ($x, $y) {    # ceil(x/y)
    (($x % $y == 0) ? 0 : 1) + divint($x, $y);
}

sub fermat_pseudoprimes_in_range ($A, $B, $k, $base) {

    $A = vecmax($A, pn_primorial($k));

    $A = Math::GMPz->new("$A");
    $B = Math::GMPz->new("$B");

    my $u = Math::GMPz::Rmpz_init();
    my $v = Math::GMPz::Rmpz_init();

    my %seen;
    my @list;

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
            $t += $L * divceil($lo - $t, $L) if ($t < $lo);

            for (my $p = $t ; $p <= $hi ; $p += $L) {
                if (is_prime_power($p) and Math::GMPz::Rmpz_gcd_ui($Math::GMPz::NULL, $m, $p) == 1 and gcd($base, $p) == 1) {

                    Math::GMPz::Rmpz_mul_ui($v, $m, $p);

                    if ($k == 1 and is_prime($p) and Math::GMPz::Rmpz_cmp_ui($m, 1) == 0) {
                        ## ok
                    }
                    elsif (Math::GMPz::Rmpz_cmp($v, $A) >= 0) {
                        Math::GMPz::Rmpz_sub_ui($u, $v, 1);
                        if (Math::GMPz::Rmpz_divisible_ui_p($u, znorder($base, $p))) {
                            push(@list, Math::GMPz::Rmpz_init_set($v)) if !$seen{Math::GMPz::Rmpz_get_str($v, 10)}++;
                        }
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

            my $z = znorder($base, $p);
            Math::GMPz::Rmpz_gcd_ui($Math::GMPz::NULL, $m, $z) == 1 or next;
            Math::GMPz::Rmpz_lcm_ui($lcm, $L, $z);

            Math::GMPz::Rmpz_set_ui($u, $p);

            for (Math::GMPz::Rmpz_mul_ui($v, $m, $p) ; Math::GMPz::Rmpz_cmp($v, $B) <= 0 ; Math::GMPz::Rmpz_mul_ui($v, $v, $p)) {
                __SUB__->($v, $lcm, $p + 1, $j - 1);
                Math::GMPz::Rmpz_mul_ui($u, $u, $p);
                powmod($base, $z, $u) == 1 or last;
            }
        }
      }
      ->(Math::GMPz->new(1), Math::GMPz->new(1), 2, $k);

    return sort { $a <=> $b } @list;
}

# Generate all the Fermat pseudoprimes to base 3 in range [1, 10^5]

my $from = 1;
my $upto = 1e5;
my $base = 3;

my @arr;
foreach my $k (1 .. 100) {
    last if pn_primorial($k) > $upto;
    push @arr, fermat_pseudoprimes_in_range($from, $upto, $k, $base);
}

say join(', ', sort { $a <=> $b } @arr);

# Run some tests

if (0) {    # true to run some tests
    foreach my $k (1 .. 5) {

        say "Testing k = $k";

        my $lo           = pn_primorial($k) * 4;
        my $hi           = mulint($lo, 1000);
        my $omega_primes = omega_primes($k, $lo, $hi);

        foreach my $base (2 .. 100) {
            my @this = grep { is_pseudoprime($_, $base) and !is_prime($_) } @$omega_primes;
            my @that = fermat_pseudoprimes_in_range($lo, $hi, $k, $base);
            join(' ', @this) eq join(' ', @that)
              or die "Error for k = $k and base = $base with hi = $hi\n(@this) != (@that)";
        }
    }
}

__END__
91, 121, 286, 671, 703, 949, 1105, 1541, 1729, 1891, 2465, 2665, 2701, 2821, 3281, 3367, 3751, 4961, 5551, 6601, 7381, 8401, 8911, 10585, 11011, 12403, 14383, 15203, 15457, 15841, 16471, 16531, 18721, 19345, 23521, 24046, 24661, 24727, 28009, 29161, 29341, 30857, 31621, 31697, 32791, 38503, 41041, 44287, 46657, 46999, 47197, 49051, 49141, 50881, 52633, 53131, 55261, 55969, 63139, 63973, 65485, 68887, 72041, 74593, 75361, 76627, 79003, 82513, 83333, 83665, 87913, 88561, 88573, 88831, 90751, 93961, 96139, 97567
