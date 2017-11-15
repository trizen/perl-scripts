#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 18 September 2017
# https://github.com/trizen

# Find the smallest number `n` such that `n!` has at least `k` factors of prime `p`.

# See also:
#   https://projecteuler.net/problem=320
#   https://en.wikipedia.org/wiki/Legendre%27s_formula

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(vecsum todigits);

sub factorial_power ($n, $p) {
    ($n - vecsum(todigits($n, $p))) / ($p - 1);
}

sub p_adic_inverse ($p, $k) {

    my $n = $k * ($p - 1);
    while (factorial_power($n, $p) < $k) {
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

say factorial_power(p_adic_inverse(7,  1234567890), 7);     #=> 1234567890
say factorial_power(p_adic_inverse(23, 1234567890), 23);    #=> 1234567890
say factorial_power(p_adic_inverse(97, 1234567890), 97);    #=> 1234567890
