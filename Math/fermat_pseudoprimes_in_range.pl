#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 31 August 2022
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
use warnings;
use ntheory qw(:all);

sub divceil ($x, $y) {    # ceil(x/y)
    (($x % $y == 0) ? 0 : 1) + divint($x, $y);
}

sub fermat_pseudoprimes_in_range ($A, $B, $k, $base) {

    $A = vecmax($A, pn_primorial($k));

    my %seen;
    my @list;

    sub ($m, $L, $lo, $j) {

        my $hi = rootint(divint($B, $m), $j);

        if ($lo > $hi) {
            return;
        }

        if ($j == 1) {

            if ($L == 1) {    # optimization
                foreach my $p (@{primes($lo, $hi)}) {

                    $base % $p == 0 and next;

                    for (my $v = (($m == 1) ? ($p * $p) : ($m * $p)) ; $v <= $B ; $v *= $p) {
                        $v >= $A                       or next;
                        powmod($base, $v - 1, $v) == 1 or last;
                        push(@list, $v) if !$seen{$v}++;
                    }
                }
                return;
            }

            my $t = invmod($m, $L);
            $t > $hi && return;
            $t += $L * divceil($lo - $t, $L) if ($t < $lo);

            for (my $p = $t ; $p <= $hi ; $p += $L) {
                if (is_prime_power($p) and gcd($m, $p) == 1 and gcd($base, $p) == 1) {

                    my $v = $m * $p;
                    $v >= $A                           or next;
                    ($v - 1) % znorder($base, $p) == 0 or next;

                    #powmod($base, $v-1, $v) == 1 or next;
                    push(@list, $v) if !$seen{$v}++;
                }
            }

            return;
        }

        foreach my $p (@{primes($lo, $hi)}) {

            $base % $p == 0 and next;

            my $z = znorder($base, $p);
            gcd($m, $z) == 1 or next;

            for (my ($q, $v) = ($p, $m * $p) ; $v <= $B ; ($q, $v) = ($q * $p, $v * $p)) {

                if ($q > $p) {
                    powmod($base, $z, $q) == 1 or last;
                }

                __SUB__->($v, lcm($L, $z), $p + 1, $j - 1);
            }
        }
      }
      ->(1, 1, 2, $k);

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

        my $lo           = pn_primorial($k);
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
