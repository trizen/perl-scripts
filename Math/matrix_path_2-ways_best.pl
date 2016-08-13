#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 08 August 2016
# Website: https://github.com/trizen

# Find the best-minimum path-sum from the top-left of a matrix, to the bottom-right.
# Inspired by: https://projecteuler.net/problem=81

# The path moves only right and down.

use 5.010;
use strict;
use warnings;

use List::Util qw(min);
use Memoize qw(memoize);

memoize('path');

my @matrix = (
              [131, 673, 234, 103, 18],
              [201, 96,  342, 965, 150],
              [630, 803, 746, 422, 111],
              [537, 699, 497, 121, 956],
              [805, 732, 524, 37,  331],
             );

my $end = $#matrix;

sub path {
    my ($i, $j) = @_;

    if ($i < $end and $j < $end) {
        return $matrix[$i][$j] + min(path($i + 1, $j), path($i, $j + 1));
    }

    if ($i < $end) {
        return $matrix[$i][$j] + path($i + 1, $j);
    }

    if ($j < $end) {
        return $matrix[$i][$j] + path($i, $j + 1);
    }

    $matrix[$i][$j];
}

say path(0, 0);
