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

use 5.020;
use warnings;

use ntheory      qw(:all);
use experimental qw(signatures);

sub divceil ($x, $y) {    # ceil(x/y)
    (($x % $y == 0) ? 0 : 1) + divint($x, $y);
}

sub lucas_carmichael_numbers_in_range ($A, $B, $k, $callback) {

    $A = vecmax($A, pn_primorial($k));

    # Largest possisble prime factor for Lucas-Carmichael numbers <= B
    my $max_p = sqrtint($B);

    sub ($m, $L, $lo, $k) {

        my $hi = vecmin($max_p, rootint(divint($B, $m), $k));

        if ($lo > $hi) {
            return;
        }

        if ($k == 1) {

            $lo = vecmax($lo, divceil($A, $m));
            $lo > $hi && return;

            my $t = $L - invmod($m, $L);
            $t > $hi && return;
            $t += $L while ($t < $lo);

            for (my $p = $t ; $p <= $hi ; $p += $L) {
                if (is_prime($p)) {
                    my $n = $m * $p;
                    if (($n + 1) % ($p + 1) == 0) {
                        $callback->($n);
                    }
                }
            }

            return;
        }

        foreach my $p (@{primes($lo, $hi)}) {

            gcd($m, $p + 1) == 1 or next;

            # gcd($m*$p, divisor_sum($m*$p)) == 1 or die "$m*$p: not Lucas-cyclic";

            __SUB__->($m * $p, lcm($L, $p + 1), $p + 1, $k - 1);
        }
      }
      ->(1, 1, 3, $k);
}

# Generate all the Lucas-Carmichael numbers with 5 prime factors in the range [100, 10^8]

my $k    = 5;
my $from = 100;
my $upto = 1e8;

my @arr;
lucas_carmichael_numbers_in_range($from, $upto, $k, sub ($n) { push @arr, $n });

say join(', ', sort { $a <=> $b } @arr);

__END__
588455, 1010735, 2276351, 2756159, 4107455, 4874639, 5669279, 6539819, 8421335, 13670855, 16184663, 16868159, 21408695, 23176439, 24685199, 25111295, 26636687, 30071327, 34347599, 34541639, 36149399, 36485015, 38999519, 39715319, 42624911, 43134959, 49412285, 49591919, 54408959, 54958799, 57872555, 57953951, 64456223, 66709019, 73019135, 77350559, 78402815, 82144799, 83618639, 86450399, 93277079, 96080039, 98803439
