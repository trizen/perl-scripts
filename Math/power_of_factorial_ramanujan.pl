#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 15 November 2017
# https://github.com/trizen

# Given a prime `p` and number `n`, the highest power of `p` dividing `n!` equals:
#   N = Sum_{k>=1} floor(n/p^k)

# In his third notebook, Ramanujan wrote the following inequalities:
#   n/(p-1) - log(n+1)/log(p) <= N <= (n-1)/(p-1)

# By writing `n` in base `p` (n = Sum_{j=0..m} (b_j * p^j), we can see that:
#   N = (n - Sum_{j=0..m} b_j) / (p-1)

use 5.020;
use strict;
use warnings;

use ntheory qw(todigits vecsum);
use experimental qw(signatures);

sub power_of_factorial_ramanujan ($n, $p) {
    ($n - vecsum(todigits($n, $p))) / ($p - 1);
}

say power_of_factorial_ramanujan(100, 2);    #=> 97
say power_of_factorial_ramanujan(100, 3);    #=> 48

say power_of_factorial_ramanujan(123456, 7);      #=> 20573
say power_of_factorial_ramanujan(123456, 127);    #=> 979
