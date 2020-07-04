#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 17 August 2016
# Website: https://github.com/trizen

# Length of shortest addition chain for n.
# Equivalently, the minimal number of multiplications required to compute n-th power.

# See also: http://oeis.org/A003313
#           https://projecteuler.net/problem=122

# (this algorithm is not efficient for n >= 35)

use 5.010;
use strict;
use warnings;

use List::Util qw(min);

sub mk {
    my ($n, $k, $pos, @nums) = @_;

    return 'inf'  if $n > $k;
    return 'inf'  if $pos > $#nums;
    return $#nums if $n == $k;

    min(
        mk($n, $k, $pos + 1, @nums),
        mk($n + $nums[$pos], $k, $pos, @nums, $n + $nums[$pos])
    );
}

for my $k (1 .. 10) {
    my $r = mk(1, $k, 0, 1);
    say "mk($k) = ", $r;
}
