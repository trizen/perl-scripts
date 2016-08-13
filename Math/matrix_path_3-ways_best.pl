#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13 August 2016
# Website: https://github.com/trizen

# The minimal path sum in the 5 by 5 matrix below, by starting in any cell
# in the left column and finishing in any cell in the right column, and only
# moving up, down, and right; the sum is equal to 994.

# This algorithm finds the best possible path.
# The problem was taken from: https://projecteuler.net/problem=82

use 5.010;
use strict;
use warnings;

no warnings 'recursion';

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
    my ($i, $j, $last) = @_;

    $j >= $end && return $matrix[$i][$j];

    my @paths;
    if ($i > 0 and $last ne 'down') {
        push @paths, path($i - 1, $j, 'up');
    }

    push @paths, path($i, $j + 1, 'ok');

    if ($i < $end and $last ne 'up') {
        push @paths, path($i + 1, $j, 'down');
    }

    my $min = 'inf';

    foreach my $sum (@paths) {
        $min = $sum if $sum < $min;
    }

    $min + $matrix[$i][$j];
}

my @sums;
foreach my $i (0 .. $end) {
    push @sums, path($i, 0, 'ok');
}

say min(@sums);
