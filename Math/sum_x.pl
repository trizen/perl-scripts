#!/usr/bin/perl

# Author: Trizen
# License: GPLv3
# Date: 03 September 2012
# http://trizen.googlecode.com

# Get sum of consecutive numbers (with a given step between numbers).
# Example: sum_x(1,3,1) returns 6  because 1+2+3   =  6
#          sum_x(1,7,2) returns 16 because 1+3+5+7 = 16

# sum_x(begin, end, step)

use 5.010;

sub sum_x {
    my ($x, $y, $z) = @_;
    return ($x + $y) * (($y - $x) / $z + 1) / 2;
}

say sum_x(shift || 1, shift || 9, shift || 1);
