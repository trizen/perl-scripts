#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 10 July 2019
# https://github.com/trizen

# The binary search algorithm: "less than or equal to" variation.

# See also:
#   https://en.wikipedia.org/wiki/Binary_search_algorithm

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

sub bsearch_le ($left, $right, $callback) {

    my ($mid, $cmp);

    for (; ;) {

        $mid = int(($left + $right) / 2);
        $cmp = $callback->($mid) || return $mid;

        if ($cmp < 0) {
            $left = $mid + 1;
            $left > $right and last;
        }
        else {
            $right = $mid - 1;

            if ($left > $right) {
                $mid -= 1;
                last;
            }
        }
    }

    return $mid;
}

say bsearch_le(0, 202,  sub ($x) { $x * $x <=> 49 });     #=> 7   (7*7  = 49)
say bsearch_le(3, 1000, sub ($x) { $x**$x <=> 3125 });    #=> 5   (5**5 = 3125)

say bsearch_le(1,    1e6, sub ($x) { exp($x) <=> 1e+9 }); #=>  20   (exp( 20) <= 1e+9)
say bsearch_le(-1e6, 1e6, sub ($x) { exp($x) <=> 1e-9 }); #=> -21   (exp(-21) <= 1e-9)
