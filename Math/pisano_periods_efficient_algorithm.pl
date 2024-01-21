#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 22 September 2018
# https://github.com/trizen

# Efficient algorithm for computing the Pisano period: period of Fibonacci
# numbers mod `n`, assuming that the factorization of `n` can be computed.

# See also:
#   https://oeis.org/A001175
#   https://oeis.org/A053031
#   https://en.wikipedia.org/wiki/Pisano_period
#   https://en.wikipedia.org/wiki/Wall%E2%80%93Sun%E2%80%93Sun_prime

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use List::Util qw(first);
use ntheory qw(divisors factor_exp);
use Math::AnyNum qw(:overload kronecker fibmod lcm factorial);

sub pisano_period_pp ($p, $k = 1) {
    $p**($k - 1) * first { fibmod($_, $p) == 0 } divisors($p - kronecker($p, 5));
}

sub pisano_period($n) {

    return 0 if ($n <= 0);
    return 1 if ($n == 1);

    my $d = lcm(map { pisano_period_pp($_->[0], $_->[1]) } factor_exp($n));

    foreach my $k (0 .. 2) {
        my $t = $d << $k;

        if ((fibmod($t, $n) == 0) and (fibmod($t + 1, $n) == 1)) {
            return $t;
        }
    }

    die "Conjecture disproved for n=$n";
}

say pisano_period(factorial(10));    #=> 86400
say pisano_period(factorial(30));    #=> 204996473853050880000000
say pisano_period(2**128 + 1);       #=> 28356863910078205764000346543980814080

say join(', ', map { pisano_period($_) } 1 .. 20);  #=> 1, 3, 8, 6, 20, 24, 16, 12, 24, 60, 10, 24, 28, 48, 40, 24, 36, 24, 18, 60
