#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13 August 2016
# Website: https://github.com/trizen

# In the 5 by 5 matrix below, the minimal path sum from the top left
# to the bottom right, by moving left, right, up, and down, is equal to 2297.

# Problem from: https://projecteuler.net/problem=83

# (this algorithm works only with matrices that are guaranteed to have a greedy path available)

use 5.010;
use strict;
use warnings;

use List::UtilsBy qw(min_by);

my @matrix = (
              [131, 673, 234, 103, 18],
              [201, 96,  342, 965, 150],
              [630, 803, 746, 422, 111],
              [537, 699, 497, 121, 956],
              [805, 732, 524, 37,  331],
             );

my @seen = "0 0";

sub valid {
    my %seen;
    @seen{@seen} = ();
    not exists $seen{"@_"};
}

my $sum = 0;
my $end = $#matrix;

my ($i, $j) = (0, 0);

while (1) {
    say $matrix[$i][$j];
    $sum += $matrix[$i][$j];

    if ($i >= $end and $j >= $end) {
        last;
    }

    my @points;

    if ($i > 0 and valid($i - 1, $j)) {
        push @points, [$i - 1, $j];
    }

    if ($j > 0 and valid($i, $j - 1)) {
        push @points, [$i, $j - 1];
    }

    if ($i < $end and valid($i + 1, $j)) {
        push @points, [$i + 1, $j];
    }

    if ($j < $end and valid($i, $j + 1)) {
        push @points, [$i, $j + 1];
    }

    @points || do {
        say "Stuck at value: $sum";
        last;
    };

    my $min = min_by { $matrix[$_->[0]][$_->[1]] } @points;

    ($i, $j) = @{$min};
    push @seen, "$i $j";
}

say "Minimum path-sum is: $sum";
