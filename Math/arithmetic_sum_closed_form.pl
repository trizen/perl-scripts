#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 20 November 2017
# https://github.com/trizen

# Compute the sum of an arithmetic sequence.

# Example: arithmetic_sum_*(1,3,1) returns 6  because 1+2+3   =  6
#          arithmetic_sum_*(1,7,2) returns 16 because 1+3+5+7 = 16

# arithmetic_sum_*(begin, end, step)

use 5.010;
use strict;
use warnings;

use experimental qw(signatures);

sub arithmetic_sum_continuous ($x, $y, $z) {
    ($x + $y) * (($y - $x) / $z + 1) / 2;
}

sub arithmetic_sum_discrete ($x, $y, $z) {
    (int(($y - $x) / $z) + 1) * ($z * int(($y - $x) / $z) + 2 * $x) / 2;
}

say arithmetic_sum_continuous(10, 113, 6);    #=> 1117.25
say arithmetic_sum_discrete(10, 113, 6);      #=> 1098
