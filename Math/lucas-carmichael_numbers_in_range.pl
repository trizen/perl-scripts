#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 27 August 2022
# https://github.com/trizen

# Generate all the Lucas-Carmichael numbers with n prime factors in a given range [a,b]. (not in sorted order)

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

# PARI/GP program (in range [A,B]) (simple):
#   lucas_carmichael(A, B, k) = A=max(A, vecprod(primes(k+1))\2); (f(m, l, lo, k) = my(list=List()); my(hi=sqrtnint(B\m, k)); if(lo > hi, return(list)); if(k==1, forprime(p=max(lo, ceil(A/m)), hi, my(t=m*p); if((t+1)%l == 0 && (t+1)%(p+1) == 0, listput(list, t))), forprime(p=lo, hi, if(gcd(m, p+1) == 1, list=concat(list, f(m*p, lcm(l, p+1), p+1, k-1))))); list); vecsort(Vec(f(1, 1, 3, k)));

# PARI/GP program (in range [A, B]) (fast):
#   lucas_carmichael(A, B, k) = A=max(A, vecprod(primes(k+1))\2); my(max_p=sqrtint(B+1)-1); (f(m, l, lo, k) = my(list=List()); my(hi=min(max_p, sqrtnint(B\m, k))); if(lo > hi, return(list)); if(k==1, lo=max(lo, ceil(A/m)); my(t=lift(-1/Mod(m,l))); while(t < lo, t += l); forstep(p=t, hi, l, if(isprime(p), my(n=m*p); if((n+1)%(p+1) == 0, listput(list, n)))), forprime(p=lo, hi, if(gcd(m, p+1) == 1, list=concat(list, f(m*p, lcm(l, p+1), p+1, k-1))))); list); vecsort(Vec(f(1, 1, 3, k)));

# PARI/GP program to generate all the Lucas-Carmichael numbers <= n (fast):
#   lucas_carmichael(A, B, k) = A=max(A, vecprod(primes(k+1))\2); my(max_p=sqrtint(B+1)-1); (f(m, l, lo, k) = my(list=List()); my(hi=min(max_p, sqrtnint(B\m, k))); if(lo > hi, return(list)); if(k==1, lo=max(lo, ceil(A/m)); my(t=lift(-1/Mod(m,l))); while(t < lo, t += l); forstep(p=t, hi, l, if(isprime(p), my(n=m*p); if((n+1)%(p+1) == 0, listput(list, n)))), forprime(p=lo, hi, if(gcd(m, p+1) == 1, list=concat(list, f(m*p, lcm(l, p+1), p+1, k-1))))); list); f(1, 1, 3, k);
#   upto(n) = my(list=List()); for(k=3, oo, if(vecprod(primes(k+1))\2 > n, break); list=concat(list, lucas_carmichael(1, n, k))); vecsort(Vec(list));

use 5.036;
use ntheory 0.74 qw(:all);

sub lucas_carmichael_numbers_in_range ($A, $B, $k) {

    $A = vecmax($A, pn_primorial($k));

    # Largest possisble prime factor for Lucas-Carmichael numbers <= B
    my $max_p = sqrtint($B);

    my @list;

    sub ($m, $L, $lo, $k) {

        my $hi = rootint(divint($B, $m), $k);

        if ($lo > $hi) {
            return;
        }

        if ($k == 1) {

            $hi = $max_p if ($hi > $max_p);
            $lo = vecmax($lo, cdivint($A, $m));
            $lo > $hi && return;

            my $t = $L - invmod($m, $L);
            $t > $hi && return;
            $t += $L * cdivint($lo - $t, $L) if ($t < $lo);

            for (my $p = $t ; $p <= $hi ; $p += $L) {
                if (($m * $p + 1) % ($p + 1) == 0 and is_prime($p)) {
                    push @list, $m * $p;
                }
            }

            return;
        }

        foreach my $p (@{primes($lo, $hi)}) {
            if (gcd($m, $p + 1) == 1) {
                __SUB__->($m * $p, lcm($L, $p + 1), $p + 1, $k - 1);
            }
        }
      }
      ->(1, 1, 3, $k);

    return sort { $a <=> $b } @list;
}

my $from = 1;
my $upto = powint(10, 12);

foreach my $k (3 .. 7) {
    my @arr = lucas_carmichael_numbers_in_range($from, $upto, $k);
    say "There are: ", scalar(@arr), " Lucas-Carmichael numbers <= $upto with $k prime factors";
}



