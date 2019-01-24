#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 20 April 2018
# https://github.com/trizen

# Compute the k-th order Fibonacci numbers.

# See also:
#   https://oeis.org/A000045    (2-nd order: Fibonacci numbers)
#   https://oeis.org/A000073    (3-rd order: Tribonacci numbers)
#   https://oeis.org/A000078    (4-th order: Tetranacci numbers)
#   https://oeis.org/A001591    (5-th order: Pentanacci numbers)

use 5.020;
use strict;
use warnings;

use ntheory qw(vecsum);
use experimental qw(signatures);

sub kth_order_fibonacci ($n, $k = 2) {

    my @A = ((0) x ($k - 1), 1);

    for (1 .. $n) {
        @A = (@A[1 .. $k - 1], vecsum(@A[0 .. $k - 1]));
    }

    return $A[-1];
}

for my $n (0 .. 20) {
    say kth_order_fibonacci($n, 5);
}
