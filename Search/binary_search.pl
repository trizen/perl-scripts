#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 10 July 2019
# https://github.com/trizen

# The binary search algorithm.

# See also:
#   https://en.wikipedia.org/wiki/Binary_search_algorithm

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

sub bsearch ($left, $right, $callback) {

    while ($left <= $right) {

        my $mid = int(($left + $right) / 2);
        my $cmp = $callback->($mid) || return $mid;

        if ($cmp > 0) {
            $right = $mid - 1;
        }
        else {
            $left = $mid + 1;
        }
    }

    return undef;
}

say bsearch(0, 202,  sub ($x) { $x * $x <=> 49 });     #=> 7   (7*7  = 49)
say bsearch(3, 1000, sub ($x) { $x**$x <=> 3125 });    #=> 5   (5**5 = 3125)
