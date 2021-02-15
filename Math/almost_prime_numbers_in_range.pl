#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 15 February 2021
# https://github.com/trizen

# Generate k-almost prime numbers in range [a,b]. (not in sorted order)

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime

use 5.020;
use ntheory qw(:all);
use experimental qw(signatures);

sub divceil ($x,$y) {   # ceil(x/y)
    my $q = divint($x, $y);
    (mulint($q, $y) == $x) ? $q : ($q+1);
}

sub almost_prime_numbers ($A, $B, $k, $callback) {

    $A = vecmax($A, powint(2, $k));

    sub ($m, $p, $r) {

        my $s = rootint(divint($B, $m), $r);

        if ($r == 1) {

            forprimes {
                $callback->(mulint($m, $_));
            } vecmax($p, divceil($A, $m)), divint($B, $m);

            return;
        }

        for (my $q = $p ; $q <= $s ; $q = next_prime($q)) {
            __SUB__->(mulint($m, $q), $q, $r - 1);
        }
    }->(1, 2, $k);
}

# Generate 5-almost primes in the range [50, 1000]

my $k    = 5;
my $from = 50;
my $upto = 1000;

my @arr; almost_prime_numbers($from, $upto, $k, sub ($n) { push @arr, $n });

my @test = grep { is_almost_prime($k, $_) } $from..$upto;   # just for testing
join(' ', sort { $a <=> $b } @arr) eq join(' ', @test) or die "Error: not equal!";

say join(', ', @arr);
