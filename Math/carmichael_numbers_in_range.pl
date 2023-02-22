#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 27 August 2022
# https://github.com/trizen

# Generate all the Carmichael numbers with n prime factors in a given range [a,b]. (not in sorted order)

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

# PARI/GP program (in range):
#   carmichael(A, B, k) = A=max(A, vecprod(primes(k+1))\2); (f(m, l, lo, k) = my(list=List()); my(hi=sqrtnint(B\m, k)); if(k==1, forprime(p=max(lo, ceil(A/m)), hi, my(t=m*p); if((t-1)%l == 0 && (t-1)%(p-1) == 0, listput(list, t))), forprime(p = lo, hi, my(t = m*p); my(L=lcm(l, p-1)); if(gcd(L, t) == 1, list=concat(list, f(t, L, p+1, k-1))))); list); vecsort(Vec(f(1, 1, 3, k)));

use 5.020;
use warnings;

use ntheory      qw(:all);
use experimental qw(signatures);

sub divceil ($x, $y) {    # ceil(x/y)
    my $q = divint($x, $y);
    ($q * $y == $x) ? $q : ($q + 1);
}

sub carmichael_numbers_in_range ($A, $B, $k, $callback) {

    $A = vecmax($A, pn_primorial($k + 1) >> 1);

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
                    my $n = $m * $p;
                    if (($n - 1) % ($p - 1) == 0) {
                        $callback->($n);
                    }
                }
            }

            return;
        }

        foreach my $p (@{primes($lo, $hi)}) {

            gcd($m, $p - 1) == 1 or next;

            # gcd($m*$p, euler_phi($m*$p)) == 1 or die "$m*$p: not cyclic";

            __SUB__->($m * $p, lcm($L, $p - 1), $p + 1, $k - 1);
        }
      }
      ->(1, 1, 3, $k);
}

# Generate all the 5-Carmichael numbers in the range [100, 10^8]

my $k    = 5;
my $from = 100;
my $upto = 1e8;

my @arr;
carmichael_numbers_in_range($from, $upto, $k, sub ($n) { push @arr, $n });

say join(', ', sort { $a <=> $b } @arr);

__END__
825265, 1050985, 9890881, 10877581, 12945745, 13992265, 16778881, 18162001, 27336673, 28787185, 31146661, 36121345, 37167361, 40280065, 41298985, 41341321, 41471521, 47006785, 67371265, 67994641, 69331969, 74165065, 75151441, 76595761, 88689601, 93614521, 93869665
