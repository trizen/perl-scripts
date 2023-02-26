#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 22 February 2023
# https://github.com/trizen

# Generate all the k-omega even Fermat pseudoprimes in range [a,b]. (not in sorted order)

# Definition:
#   k-omega primes are numbers n such that omega(n) = k.

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://en.wikipedia.org/wiki/Prime_omega_function
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

# OEIS sequences:
#   https://oeis.org/A006935 -- Even pseudoprimes to base 2
#   https://oeis.org/A130433 -- Even pseudoprimes to base 3

# PARI/GP program:
#   even_fermat_psp(A, B, k, base) = A=max(A, vecprod(primes(k))); (f(m, l, p, j) = my(list=List()); forprime(q=p, sqrtnint(B\m, j), if(base%q != 0, my(v=m*q, t=q); while(v <= B, my(L=lcm(l, znorder(Mod(base, t)))); if(gcd(L, v) == 1, if(j==1, if(v>=A && if(k==1, !isprime(v), 1) && (v-1)%L == 0, listput(list, v)), list=concat(list, f(v, L, q+1, j-1))), break); v *= q; t *= q))); list); vecsort(Vec(f(2, 1, 3, k-1)));

use 5.020;
use warnings;

use ntheory      qw(:all);
use experimental qw(signatures);

sub even_fermat_pseudoprimes_in_range ($A, $B, $k, $base, $callback) {

    if ($k <= 1) {
        return;
    }

    $A = vecmax($A, pn_primorial($k));

    sub ($m, $L, $lo, $j) {

        my $hi = rootint(divint($B, $m), $j);

        if ($lo > $hi) {
            return;
        }

        if ($j == 1) {

            if ($L == 1) {    # optimization
                foreach my $p (@{primes($lo, $hi)}) {

                    $base % $p == 0 and next;

                    for (my ($q, $v) = ($p, $m * $p) ; $v <= $B ; ($q, $v) = ($q * $p, $v * $p)) {
                        $v >= $A or next;
                        $k == 1 and is_prime($v) and next;
                        ($v - 1) % znorder($base, $q) == 0 or next;
                        $callback->($v);
                    }
                }
                return;
            }

            my $t = invmod($m, $L);
            $t > $hi && return;
            $t += $L while ($t < $lo);

            for (my $p = $t ; $p <= $hi ; $p += $L) {
                if (is_prime($p) and $base % $p != 0) {
                    for (my ($q, $v) = ($p, $m * $p) ; $v <= $B ; ($q, $v) = ($q * $p, $v * $p)) {
                        $v >= $A or next;
                        $k == 1 and is_prime($v) and next;
                        ($v - 1) % $L == 0                 or next;
                        ($v - 1) % znorder($base, $q) == 0 or next;
                        $callback->($v);
                    }
                }
            }

            return;
        }

        foreach my $p (@{primes($lo, $hi)}) {

            $base % $p == 0 and next;

            for (my ($q, $v) = ($p, $m * $p) ; $v <= $B ; ($q, $v) = ($q * $p, $v * $p)) {
                my $z = znorder($base, $q);
                gcd($v, $z) == 1 or last;
                __SUB__->($v, lcm($L, $z), $p + 1, $j - 1);
            }
        }
      }
      ->(2, 1, 3, $k - 1);
}

# Generate all the even Fermat pseudoprimes to base 2 in range [1, 10^5]

my $from = 1;
my $upto = 1e7;
my $base = 2;

my @arr;
foreach my $k (1 .. 100) {
    last if pn_primorial($k) > $upto;
    even_fermat_pseudoprimes_in_range($from, $upto, $k, $base, sub ($n) { push @arr, $n });
}

say join(', ', sort { $a <=> $b } @arr);

__END__
161038, 215326, 2568226, 3020626, 7866046, 9115426
