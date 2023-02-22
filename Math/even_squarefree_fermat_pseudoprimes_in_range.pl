#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 22 February 2023
# https://github.com/trizen

# Generate all the even squarefree Fermat pseudoprimes to a given base with n prime factors in a given range [A,B]. (not in sorted order)

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

# PARI/GP program (in range):
#   squarefree_fermat(A, B, k, base=2) = A=max(A, vecprod(primes(k))); (f(m, l, p, k, u=0, v=0) = my(list=List()); if(k==1, forprime(p=u, v, if(base%p != 0, my(t=m*p); if((t-1)%l == 0 && (t-1)%znorder(Mod(base, p)) == 0, listput(list, t)))), forprime(q = p, sqrtnint(B\m, k), my(t = m*q); if (base%q != 0, my(L=lcm(l, znorder(Mod(base, q)))); if(gcd(L, t) == 1, my(u=ceil(A/t), v=B\t); if(u <= v, my(r=nextprime(q+1)); if(k==2 && r>u, u=r); list=concat(list, f(t, L, r, k-1, u, v))))))); list); vecsort(Vec(f(1, 1, 2, k)));

use 5.020;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub divceil ($x,$y) {   # ceil(x/y)
    my $q = divint($x, $y);
    ($q*$y == $x) ? $q : ($q+1);
}

sub even_squarefree_fermat_pseudoprimes_in_range ($A, $B, $k, $base, $callback) {

    $A = vecmax($A, pn_primorial($k));

    if ($k <= 1) {
        return;
    }

    sub ($m, $L, $lo, $k) {

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
                    if (($m*$p - 1) % znorder($base, $p) == 0) {
                        $callback->($m*$p);
                    }
                }
            }

            return;
        }

        foreach my $p (@{primes($lo, $hi)}) {

            $base % $p == 0 and next;

            my $z = znorder($base, $p);
            gcd($m, $z) == 1 or next;

            __SUB__->($m * $p, lcm($L, $z), $p + 1, $k - 1);
        }
      }
      ->(2, 1, 3, $k-1);
}

# Generate all the even squarefree Fermat pseudoprimes to base 2 with 5 prime factors in the range [100, 10^10]

my $k    = 5;
my $base = 2;
my $from = 100;
my $upto = 1e11;

my @arr; even_squarefree_fermat_pseudoprimes_in_range($from, $upto, $k, $base, sub ($n) { push @arr, $n });

say join(', ', sort { $a <=> $b } @arr);

__END__
209665666, 213388066, 377994926, 1066079026, 1105826338, 1423998226, 1451887438, 2952654706, 3220041826, 6182224786, 6381449614, 9548385826, 14184805006, 14965276226, 14973142786, 15369282226, 16732427362, 18411253246, 18661908574, 30789370162, 30910262626, 37130195614, 43487454286, 44849716066, 74562118786, 79204064626, 82284719986, 83720640862, 85898088046, 98730252226
