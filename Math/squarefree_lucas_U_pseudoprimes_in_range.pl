#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 06 September 2022
# https://github.com/trizen

# Generate all the squarefree Lucas pseudoprimes to the U_n(P,Q) sequence with n prime factors in a given range [a,b]. (not in sorted order)

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://en.wikipedia.org/wiki/Lucas_sequence
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

use 5.020;
use warnings;

use ntheory      qw(:all);
use experimental qw(signatures);

sub divceil ($x, $y) {    # ceil(x/y)
    my $q = divint($x, $y);
    ($q * $y == $x) ? $q : ($q + 1);
}

sub lucas_znorder ($P, $Q, $D, $n) {

    foreach my $d (divisors($n - kronecker($D, $n))) {
        my ($u, $v) = lucas_sequence($n, $P, $Q, $d);
        if ($u == 0) {
            return $d;
        }
    }

    return undef;
}

sub squarefree_lucas_U_pseudoprimes_in_range ($A, $B, $k, $P, $Q, $callback) {

    $A = vecmax($A, pn_primorial($k));
    my $D = $P * $P - 4 * $Q;

    sub ($m, $L, $lo, $k) {

        my $hi = rootint(divint($B, $m), $k);

        if ($lo > $hi) {
            return;
        }

        if ($k == 1) {

            $lo = vecmax($lo, divceil($A, $m));
            $lo > $hi && return;

            foreach my $j (1, -1) {

                my $t = mulmod(invmod($m, $L), $j, $L);
                $t > $hi && next;
                $t += $L while ($t < $lo);

                for (my $p = $t ; $p <= $hi ; $p += $L) {
                    if (is_prime($p)) {
                        my $n = $m * $p;
                        my $w = $n - kronecker($D, $n);
                        if ($w % $L == 0 and $w % lucas_znorder($P, $Q, $D, $p) == 0) {
                            $callback->($n);
                        }
                    }
                }
            }

            return;
        }

        foreach my $p (@{primes($lo, $hi)}) {

            $D % $p == 0 and next;

            my $z = lucas_znorder($P, $Q, $D, $p) // next;
            gcd($m, $z) == 1 or next;

            __SUB__->($m * $p, lcm($L, $z), $p + 1, $k - 1);
        }
      }
      ->(1, 1, 2, $k);
}

# Generate all the squarefree Fibonacci pseudoprimes in the range [1, 64681]

my $from = 1;
my $upto = 64681;
my ($P, $Q) = (1, -1);

my @arr;
foreach my $k (2 .. 100) {
    last if pn_primorial($k) > $upto;
    squarefree_lucas_U_pseudoprimes_in_range($from, $upto, $k, $P, $Q, sub ($n) { push @arr, $n });
}

say join(', ', sort { $a <=> $b } @arr);

__END__
323, 377, 1891, 3827, 4181, 5777, 6601, 6721, 8149, 10877, 11663, 13201, 13981, 15251, 17119, 17711, 18407, 19043, 23407, 25877, 27323, 30889, 34561, 34943, 35207, 39203, 40501, 50183, 51841, 51983, 52701, 53663, 60377, 64079, 64681
