#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 24 September 2022
# https://github.com/trizen

# Generate all the k-omega strong Fermat pseudoprimes in range [A,B]. (not in sorted order)

# Definition:
#   k-omega primes are numbers n such that omega(n) = k.

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://en.wikipedia.org/wiki/Prime_omega_function
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

# PARI/GP program (version 1):
#   strong_fermat_psp(A, B, k, base) = A=max(A, vecprod(primes(k))); (f(m, l, p, j, k_exp, congr) = my(list=List()); forprime(q=p, sqrtnint(B\m, j), if(base%q != 0, my(tv=valuation(q-1, 2)); if(tv > k_exp && Mod(base, q)^(((q-1)>>tv)<<k_exp) == congr, my(v=m*q, t=q, r=nextprime(q+1)); while(v <= B, my(L=lcm(l, znorder(Mod(base, t)))); if(gcd(L, v) == 1, if(j==1, if(v>=A && if(k==1, !isprime(v), 1) && (v-1)%L == 0, listput(list, v)), if(v*r <= B, list=concat(list, f(v, L, r, j-1, k_exp, congr)))), break); v *= q; t *= q)))); list); my(r=f(1, 1, 2, k, 0, 1)); for(v=0, logint(B, 2), r=concat(r, f(1, 1, 2, k, v, -1))); vecsort(Vec(r));

# PARI/GP program (version 2):
#   strong_fermat_psp(A, B, k, base) = A=max(A, vecprod(primes(k))); (f(m, l, p, j, k_exp, congr) = my(list=List()); forprime(q=p, sqrtnint(B\m, j), if(base%q != 0, my(tv=valuation(q-1, 2)); if(tv > k_exp && Mod(base, q)^(((q-1)>>tv)<<k_exp) == congr, my(v=m*q, t=q, r=nextprime(q+1)); while(v <= B, my(L=lcm(l, znorder(Mod(base, t)))); if(gcd(L, v) == 1, my(tv=valuation(t-1, 2)); if(tv > k_exp && Mod(base, t)^(((t-1)>>tv)<<k_exp) == congr, if(j==1, if(v>=A && if(k==1, !isprime(v), 1) && (v-1)%L == 0, listput(list, v)), if(v*r <= B, list=concat(list, f(v, L, r, j-1, k_exp, congr))))), break); v *= q; t *= q)))); list); my(r=f(1, 1, 2, k, 0, 1)); for(v=0, logint(B, 2), r=concat(r, f(1, 1, 2, k, v, -1))); vecsort(Vec(r));

use 5.020;
use warnings;

use ntheory      qw(:all);
use experimental qw(signatures);

sub strong_fermat_pseudoprimes_in_range ($A, $B, $k, $base, $callback) {

    $A = vecmax($A, pn_primorial($k));
    $A > $B and return;

    my %seen;

    my $generator = sub ($m, $L, $lo, $j, $k_exp, $congr) {

        my $hi = rootint(divint($B, $m), $j);

        if ($lo > $hi) {
            return;
        }

        if ($j == 1) {

            if ($L == 1) {    # optimization
                foreach my $p (@{primes($lo, $hi)}) {

                    $base % $p == 0 and next;

                    my $val = valuation($p - 1, 2);
                    $val > $k_exp                                                   or next;
                    powmod($base, ($p - 1) >> ($val - $k_exp), $p) == ($congr % $p) or next;

                    for (my ($q, $v) = ($p, $m * $p) ; $v <= $B ; ($q, $v) = ($q * $p, $v * $p)) {
                        $v >= $A or next;
                        $k == 1 and is_prime($v) and next;
                        ($v - 1) % znorder($base, $q) == 0 or next;
                        $callback->($v) if !$seen{$v}++;
                    }
                }
                return;
            }

            my $t = invmod($m, $L);
            $t > $hi && return;
            $t += $L while ($t < $lo);

            for (my $p = $t ; $p <= $hi ; $p += $L) {

                my $val = valuation($p - 1, 2);
                $val > $k_exp                                                   or next;
                powmod($base, ($p - 1) >> ($val - $k_exp), $p) == ($congr % $p) or next;

                if (is_prime_power($p) and gcd($m, $p) == 1 and gcd($base, $p) == 1) {
                    my $v = $m * $p;
                    $v >= $A or next;
                    $k == 1 and is_prime($v) and next;
                    ($v - 1) % znorder($base, $p) == 0 or next;
                    $callback->($v) if !$seen{$v}++;
                }
            }

            return;
        }

        foreach my $p (@{primes($lo, $hi)}) {

            $base % $p == 0 and next;

            my $val = valuation($p - 1, 2);
            $val > $k_exp                                                   or next;
            powmod($base, ($p - 1) >> ($val - $k_exp), $p) == ($congr % $p) or next;

            for (my ($q, $v) = ($p, $m * $p) ; $v <= $B ; ($q, $v) = ($q * $p, $v * $p)) {
                my $z = znorder($base, $q);
                gcd($v, $z) == 1 or last;
                __SUB__->($v, lcm($L, $z), $p + 1, $j - 1, $k_exp, $congr);
            }
        }
    };

    # Case where 2^d == 1 (mod p), where d is the odd part of p-1.
    $generator->(1, 1, 2, $k, 0, 1);

    # Cases where 2^(d * 2^v) == -1 (mod p), for some v >= 0.
    foreach my $v (0 .. logint($B, 2)) {
        $generator->(1, 1, 2, $k, $v, -1);
    }
}

# Generate all the Fermat pseudoprimes to base 3 in range [1, 10^5]

my $from = 1;
my $upto = 1e5;
my $base = 3;

my @arr;
foreach my $k (1 .. 100) {
    last if pn_primorial($k) > $upto;
    strong_fermat_pseudoprimes_in_range($from, $upto, $k, $base, sub ($n) { push @arr, $n });
}

say join(', ', sort { $a <=> $b } @arr);

# Run some tests

if (0) {    # true to run some tests
    foreach my $k (1 .. 5) {

        my $lo           = pn_primorial($k);
        my $hi           = mulint($lo, 10000);
        my $omega_primes = omega_primes($k, $lo, $hi);

        foreach my $base (2 .. 100) {
            my @this = grep { is_strong_pseudoprime($_, $base) and !is_prime($_) } @$omega_primes;
            my @that;
            strong_fermat_pseudoprimes_in_range($lo, $hi, $k, $base, sub ($n) { push @that, $n });
            @that = sort { $a <=> $b } @that;
            join(' ', @this) eq join(' ', @that)
              or die "Error for k = $k and base = $base with hi = $hi\n(@this) != (@that)";
        }
    }
}

__END__
121, 703, 1891, 3281, 8401, 8911, 10585, 12403, 16531, 18721, 19345, 23521, 31621, 44287, 47197, 55969, 63139, 74593, 79003, 82513, 87913, 88573, 97567
