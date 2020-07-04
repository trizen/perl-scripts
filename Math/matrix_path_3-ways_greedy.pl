#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13 August 2016
# Website: https://github.com/trizen

# The minimal path sum in the 5 by 5 matrix below, by starting in any cell
# in the left column and finishing in any cell in the right column, and only
# moving up, down, and right; the sum is equal to 994.

# This is a greedy algorithm.
# The problem was taken from: https://projecteuler.net/problem=82

use 5.010;
use strict;
use warnings;

my @matrix = (
              [131, 673, 234, 103, 18],
              [201, 96,  342, 965, 150],
              [630, 803, 746, 422, 111],
              [537, 699, 497, 121, 956],
              [805, 732, 524, 37,  331],
             );

my $end = $#matrix;
my $min = 'inf';

foreach my $i (0 .. $#matrix) {
    my $sum = $matrix[$i][0];

    my $j    = 0;
    my $last = 'ok';

    while (1) {
        my @ways;

        if ($i > 0 and $last ne 'down') {
            push @ways, [-1, 0, $matrix[$i - 1][$j], 'up'];
        }

        if ($j < $end) {
            push @ways, [0, 1, $matrix[$i][$j + 1], 'ok'];
        }

        if ($i < $end and $last ne 'up') {
            push @ways, [1, 0, $matrix[$i + 1][$j], 'down'];
        }

        my $m = [0, 0, 'inf', 'ok'];

        foreach my $way (@ways) {
            $m = $way if $way->[2] < $m->[2];
        }

        $i   += $m->[0];
        $j   += $m->[1];
        $sum += $m->[2];
        $last = $m->[3];

        last if $j >= $end;
    }

    $min = $sum if $sum < $min;
}

say $min;
