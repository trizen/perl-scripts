#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 28 April 2017
# https://github.com/trizen

# Find the smallest representations for natural numbers as the difference of some k power.

# Example:
#   781 =  4^5 - 3^5
#   992 = 10^3 - 2^3
#   999 = 32^2 - 5^2

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(root ceil log2);

OUTER: foreach my $n (1 .. 1000) {
    foreach my $i (2 .. ceil(log2($n))) {
        my $s = ceil(root($n, $i));
        foreach my $k (0 .. $s) {
            if ($s**$i - $k**$i == $n) {
                say "$n = $s^$i - $k^$i";
                next OUTER;
            }
        }
    }
}
