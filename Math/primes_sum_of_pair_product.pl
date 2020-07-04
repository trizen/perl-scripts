#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 07 April 2016
# Website: https://github.com/trizen

# Sum of product of pair of primes that differ by a given constant.
#   ∞
#  ---
#  \     1     1
#  /    --- * ---
#  ---   p    p+c
#  p
#  p+c

use 5.010;
use strict;

use ntheory qw(is_prime forprimes);

my $C = 2;      # 2 is for twin primes
my $j = 0;
my $S = 0.0;

forprimes {
    is_prime($j = $_ + $C) && (
        $S += 1 / ($_ * $j)
    );
} 1, 1000000000;

say $S;
