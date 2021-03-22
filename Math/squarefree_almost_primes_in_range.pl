#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 10 March 2021
# https://github.com/trizen

# Generate squarefree k-almost prime numbers in range [a,b]. (not in sorted order)

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime

use 5.020;
use ntheory qw(:all);
use experimental qw(signatures);

sub divceil ($x,$y) {   # ceil(x/y)
    my $q = divint($x, $y);
    (mulint($q, $y) == $x) ? $q : ($q+1);
}

sub squarefree_almost_primes ($A, $B, $k, $callback) {

    $A = vecmax($A, pn_primorial($k));

    sub ($m, $p, $k, $u = undef, $v = undef) {

        if ($k == 1) {

            forprimes {
                $callback->(mulint($m, $_));
            } $u, $v;

            return;
        }

        my $s = rootint(divint($B, $m), $k);

        while ($p <= $s) {

            my $r = next_prime($p);
            my $t = mulint($m, $p);
            my $u = divceil($A, $t);
            my $v = divint($B, $t);

            if ($u <= $v) {
                __SUB__->($t, $r, $k - 1, (($k==2 && $r>$u) ? $r : $u), $v);
            }

            $p = $r;
        }
    }->(1, 2, $k);
}

# Generate squarefree 5-almost primes in the range [3000, 10000]

my $k    = 5;
my $from = 3000;
my $upto = 10000;

my @arr; squarefree_almost_primes($from, $upto, $k, sub ($n) { push @arr, $n });

my @test = grep { is_almost_prime($k, $_) && is_square_free($_) } $from..$upto;   # just for testing
join(' ', sort { $a <=> $b } @arr) eq join(' ', @test) or die "Error: not equal!";

say join(', ', @arr);
