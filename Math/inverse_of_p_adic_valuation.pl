#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 18 September 2017
# https://github.com/trizen

# Find the smallest number `n` such that `n!` has at least `k` factors of prime `p`.

# See also:
#   https://projecteuler.net/problem=320
#   https://en.wikipedia.org/wiki/Legendre%27s_formula

use 5.010;
use strict;
use warnings;

use experimental qw(signatures);

sub p_adic_valuation {
    my ($n, $p) = @_;

    my $s = 0;
    while ($n >= $p) {
        $s += int($n /= $p);
    }

    return $s;
}

sub p_adic_inverse {
    my ($p, $k) = @_;

    my $n = $k * ($p - 1);
    while (p_adic_valuation($n, $p) < $k) {
        $n -= $n % $p;
        $n += $p;
    }

    return $n;
}

say p_adic_inverse(2,  100);           #=> 104
say p_adic_inverse(3,  51);            #=> 108
say p_adic_inverse(2,  992);           #=> 1000
say p_adic_inverse(13, 83333329);      #=> 999999988
say p_adic_inverse(97, 1234567890);    #=> 118518517733

say p_adic_valuation(p_adic_inverse(7,  1234567890), 7);     #=> 1234567890
say p_adic_valuation(p_adic_inverse(23, 1234567890), 23);    #=> 1234567890
say p_adic_valuation(p_adic_inverse(97, 1234567890), 97);    #=> 1234567890
