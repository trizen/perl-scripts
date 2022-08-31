#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 28 August 2022
# https://github.com/trizen

# Generate all the squarefree Fermat overpseudoprimes to given a base with n prime factors in a given range [a,b]. (not in sorted order)

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

use 5.020;
use warnings;
use ntheory qw(:all);
use experimental qw(signatures);

sub divceil ($x,$y) {   # ceil(x/y)
    my $q = divint($x, $y);
    ($q*$y == $x) ? $q : ($q+1);
}

sub squarefree_fermat_overpseudoprimes_in_range ($A, $B, $k, $base, $callback) {

    $A = vecmax($A, pn_primorial($k));

    sub ($m, $lambda, $p, $k, $u = undef, $v = undef) {

        if ($k == 1) {

            forprimes {
                if (($m*$_ - 1)%$lambda == 0 and znorder($base, $_) == $lambda) {
                    $callback->($m*$_);
                }
            } $u, $v;

            return;
        }

        my $s = rootint(divint($B, $m), $k);

        for(my $r; $p <= $s; $p = $r) {

            $r = next_prime($p);
            $base % $p == 0 and next;

            my $L = znorder($base, $p);
            $L == $lambda or $lambda == 1 or next;

            gcd($L, $m) == 1 or next;

            my $t = $m*$p;
            my $u = divceil($A, $t);
            my $v = divint($B, $t);

            if ($u <= $v) {
                __SUB__->($t, $L, $r, $k - 1, (($k==2 && $r>$u) ? $r : $u), $v);
            }
        }
    }->(1, 1, 2, $k);
}

# Generate all the squarefree Fermat overpseudoprimes to base 2 with 3 prime factors in the range [13421773, 4123462001]

my $k    = 3;
my $base = 2;
my $from = 13421773;
my $upto = 4123462001;

my @arr; squarefree_fermat_overpseudoprimes_in_range($from, $upto, $k, $base, sub ($n) { push @arr, $n });

say join(', ', sort { $a <=> $b } @arr);

__END__
13421773, 464955857, 536870911, 1220114377, 1541955409, 2454285751, 3435973837
