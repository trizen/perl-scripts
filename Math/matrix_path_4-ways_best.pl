#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 08 August 2016
# Website: https://github.com/trizen

# In the 5 by 5 matrix below, the minimal path sum from the top left
# to the bottom right, by moving left, right, up, and down, is equal to 2297.

# Problem from: https://projecteuler.net/problem=83

# (this algorithm is not scalable for matrices beyond 5x5)

use 5.010;
use strict;
use warnings;

use List::Util qw(min);

my @matrix = (
              [131, 673, 234, 103, 18],
              [201, 96,  342, 965, 150],
              [630, 803, 746, 422, 111],
              [537, 699, 497, 121, 956],
              [805, 732, 524, 37,  331],
             );

my %seen;
my $end = $#matrix;

sub rec {
    my ($i, $j, @vecs) = @_;

    @vecs = (
             grep { not exists $seen{"@{$_}"} }
             map { [$_->[0] + $i, $_->[1] + $j] } @vecs
            );

    @vecs || return 'inf';

    undef $seen{"$i $j"};
    my $res = $matrix[$i][$j] + min(map { path(@{$_}) } @vecs);
    delete $seen{"$i $j"};

    return $res;
}

sub path {
    my ($i, $j) = @_;

    if ($i == 0 and $j == 0) {
        return rec($i, $j, [1, 0], [0, 1]);
    }

    if ($i == 0 and $j == $end) {
        return rec($i, $j, [0, -1], [1, 0]);
    }

    if ($i == $end and $j == 0) {
        return rec($i, $j, [-1, 0], [0, 1]);
    }

    if ($i == 0 and $j > 0 and $j < $end) {
        return rec($i, $j, [1, 0], [0, 1], [0, -1]);
    }

    if ($i == $end and $j > 0 and $j < $end) {
        return rec($i, $j, [-1, 0], [0, -1], [0, 1]);
    }

    if ($j == 0 and $i > 0 and $i < $end) {
        return rec($i, $j, [-1, 0], [1, 0], [0, 1]);
    }

    if ($j == $end and $i > 0 and $i < $end) {
        return rec($i, $j, [-1, 0], [1, 0], [0, -1]);
    }

    if ($i > 0 and $j > 0 and $i < $end and $j < $end) {
        return rec($i, $j, [1, 0], [0, 1], [-1, 0], [0, -1]);
    }

    $matrix[$i][$j];
}

say path(0, 0);
