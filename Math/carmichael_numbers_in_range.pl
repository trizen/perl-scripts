#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 27 August 2022
# Edit: 09 March 2026
# https://github.com/trizen

# Generate all the Carmichael numbers with n prime factors in a given range [a,b].

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

# PARI/GP program (in range) (simple):
#   carmichael(A, B, k) = A=max(A, vecprod(primes(k+1))\2); (f(m, l, lo, k) = my(list=List()); my(hi=sqrtnint(B\m, k)); if(k==1, forprime(p=max(lo, ceil(A/m)), hi, my(t=m*p); if((t-1)%l == 0 && (t-1)%(p-1) == 0, listput(list, t))), forprime(p = lo, hi, my(t = m*p); my(L=lcm(l, p-1)); if(gcd(L, t) == 1, list=concat(list, f(t, L, p+1, k-1))))); list); vecsort(Vec(f(1, 1, 3, k)));

# PARI/GP program (in range) (fast):
#   carmichael(A, B, k) = A=max(A, vecprod(primes(k+1))\2); my(max_p=(1+sqrtint(8*B+1))\4); (f(m, l, lo, k) = my(list=List()); my(hi=min(max_p, sqrtnint(B\m, k))); if(lo > hi, return(list)); if(k==1, lo=max(lo, ceil(A/m)); my(t=lift(1/Mod(m,l))); while(t < lo, t += l); forstep(p=t, hi, l, if(isprime(p), my(n=m*p); if((n-1)%(p-1) == 0, listput(list, n)))), forprime(p=lo, hi, if(gcd(m, p-1) == 1, list=concat(list, f(m*p, lcm(l, p-1), p+1, k-1))))); list); vecsort(Vec(f(1, 1, 3, k)));

# PARI/GP program to generate all the Carmichael numbers <= n (fast):
#   carmichael(A, B, k) = A=max(A, vecprod(primes(k+1))\2); my(max_p=(1+sqrtint(8*B+1))\4); (f(m, l, lo, k) = my(list=List()); my(hi=min(max_p, sqrtnint(B\m, k))); if(lo > hi, return(list)); if(k==1, lo=max(lo, ceil(A/m)); my(t=lift(1/Mod(m,l))); while(t < lo, t += l); forstep(p=t, hi, l, if(isprime(p), my(n=m*p); if((n-1)%(p-1) == 0, listput(list, n)))), forprime(p=lo, hi, if(gcd(m, p-1) == 1, list=concat(list, f(m*p, lcm(l, p-1), p+1, k-1))))); list); f(1, 1, 3, k);
#   upto(n) = my(list=List()); for(k=3, oo, if(vecprod(primes(k+1))\2 > n, break); list=concat(list, carmichael(1, n, k))); vecsort(Vec(list));

use 5.036;
use ntheory 0.74 qw(:all);

sub carmichael_numbers_in_range ($A, $B, $k) {

    $A = vecmax($A, pn_primorial($k + 1) >> 1);

    # Largest possisble prime factor for Carmichael numbers <= B
    my $max_p = (1 + sqrtint(8 * $B + 1)) >> 2;

    my @list;

    sub ($m, $L, $lo, $k) {

        my $hi = rootint(divint($B, $m), $k);

        $lo > $hi && return;

        # Pinch's bound for the second to last prime
        if ($k == 2 and $m < 1_000) {
            my $bound = 2 * $m * $m - 3 * $m + 2;
            if ($hi > $bound) {
                $hi = $bound;
                $lo > $hi && return;
            }
        }

        if ($k == 1) {

            $hi = $m     if ($m < $hi);       # the last prime p_k must be <= m
            $hi = $max_p if ($max_p < $hi);
            $lo = vecmax($lo, cdivint($A, $m));
            $lo > $hi && return;

            my $inv_m = invmod($m, $L);
            $inv_m > $hi && return;

            my $t = $inv_m;
            $t += $L * cdivint($lo - $t, $L) if ($t < $lo);
            $t > $hi && return;

            if (divint($hi - $t, $L) < 1_000) {

                # Approach 1: Fast linear scan for small search spaces
                for (my $p = $t ; $p <= $hi ; $p += $L) {
                    if (($m * $p - 1) % ($p - 1) == 0 and is_prime($p)) {
                        push @list, $m * $p;
                    }
                }
            }
            else {
                # Approach 2: Combinatorial divisor extraction for large spaces
                foreach my $d (divisors($m - 1, $hi)) {
                    my $p = $d + 1;

                    next if $p < $lo;
                    last if $p > $hi;

                    # Only check the congruence and primality
                    if ($p % $L == $inv_m and is_prime($p)) {
                        push @list, $m * $p;
                    }
                }
            }

            return;
        }

        foreach my $p (@{primes($lo, $hi)}) {
            if (gcd($m, $p >> 1) == 1) {
                __SUB__->($m * $p, lcm($L, $p - 1), $p + 1, $k - 1);
            }
        }
      }
      ->(1, 1, 3, $k);

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
