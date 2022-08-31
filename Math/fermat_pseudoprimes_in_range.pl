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

# PARI/GP program (in range):
#   fermat_psp(A, B, k, base=2) = A=max(A, vecprod(primes(k))); (f(m, l, p, j) = my(list=List()); forprime(q=p, sqrtnint(B\m, j), if(base%q != 0, my(z=znorder(Mod(base, q)), L=lcm(l, z)); if(gcd(L, m)==1, my(v=m*q, r=nextprime(q+1)); while(v <= B, if(j==1, if(v>=A && if(k==1, !isprime(v), 1) && (v-1)%l == 0 && (v-1)%z == 0 && Mod(base, v)^(v-1) == 1, listput(list, v)), if(v*r <= B, list=concat(list, f(v, l, r, j-1)))); v *= q)))); list); vecsort(Vec(f(1, 1, 2, k)));

use 5.020;
use warnings;

use ntheory      qw(:all);
use experimental qw(signatures);

sub fermat_pseudoprimes ($A, $B, $k, $base, $callback) {

    $A = vecmax($A, pn_primorial($k));

    sub ($m, $lambda, $p, $j) {

        my $s = rootint(divint($B, $m), $j);

        for (my $r ; $p <= $s ; $p = $r) {

            $r = next_prime($p);

            if ($base % $p == 0) {
                next;
            }

            my $z = znorder($base, $p);
            my $L = lcm($lambda, $z);

            gcd($L, $m) == 1 or next;

            for (my $v = $m * $p ; $v <= $B ; $v *= $p) {

                if ($j == 1) {
                    $v >= $A or next;
                    $k == 1 and is_prime($v) and next;
                    ($v - 1) % $lambda == 0        or next;
                    ($v - 1) % $z == 0             or next;
                    powmod($base, $v - 1, $v) == 1 or next;
                    $callback->($v);
                    next;
                }

                $v * $r <= $B or next;
                __SUB__->($v, $L, $r, $j - 1);
            }
        }
      }
      ->(1, 1, 2, $k);
}

# Generate all the Fermat pseudoprimes to base 3 in range [1, 10^5]

my $from = 1;
my $upto = 1e5;
my $base = 3;

my @arr;
foreach my $k (1 .. 100) {
    last if pn_primorial($k) > $upto;
    fermat_pseudoprimes($from, $upto, $k, $base, sub ($n) { push @arr, $n });
}

say join(', ', sort { $a <=> $b } @arr);

__END__
91, 121, 286, 671, 703, 949, 1105, 1541, 1729, 1891, 2465, 2665, 2701, 2821, 3281, 3367, 3751, 4961, 5551, 6601, 7381, 8401, 8911, 10585, 11011, 12403, 14383, 15203, 15457, 15841, 16471, 16531, 18721, 19345, 23521, 24046, 24661, 24727, 28009, 29161, 29341, 30857, 31621, 31697, 32791, 38503, 41041, 44287, 46657, 46999, 47197, 49051, 49141, 50881, 52633, 53131, 55261, 55969, 63139, 63973, 65485, 68887, 72041, 74593, 75361, 76627, 79003, 82513, 83333, 83665, 87913, 88561, 88573, 88831, 90751, 93961, 96139, 97567
