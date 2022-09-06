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

    sub ($m, $lambda, $p, $k, $u = undef, $v = undef) {

        if ($k == 1) {

            forprimes {
                my $t = $m * $_;
                my $w = $t - kronecker($D, $t);
                if ($w % $lambda == 0 and $w % lucas_znorder($P, $Q, $D, $_) == 0) {
                    $callback->($t);
                }
            } $u, $v;

            return;
        }

        my $s = rootint(divint($B, $m), $k);

        for (my $r ; $p <= $s ; $p = $r) {

            $r = next_prime($p);
            $D % $p == 0 and next;

            my $z = lucas_znorder($P, $Q, $D, $p) // next;
            my $L = lcm($lambda, $z);

            gcd($L, $m) == 1 or next;

            my $t = $m * $p;
            my $u = divceil($A, $t);
            my $v = divint($B, $t);

            if ($u <= $v) {
                __SUB__->($t, $L, $r, $k - 1, (($k == 2 && $r > $u) ? $r : $u), $v);
            }
        }
    }->(1, 1, 2, $k);
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
