#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 04 August 2017
# https://github.com/trizen

# Find the lowest-cost possible path in a matrix, by starting
# in the top-left corner of the matrix and finishing in the
# bottom-right corner, and only moving up, down, and right.

# Problem closely related to:
#   https://projecteuler.net/problem=82

use 5.010;
use strict;
use warnings;

no warnings 'recursion';

use List::Util qw(min);
use Memoize qw(memoize);

memoize('path');

my @matrix = (
              [131, 673,   4, 103,  18],
              [ 21,  96, 342, 965, 150],
              [630, 803, 746, 422, 111],
              [537, 699, 497, 121,  56],
              [805, 732, 524,  37, 331],
             );

my $end = $#matrix;

sub path {
    my ($i, $j, $last, @path) = @_;

    if ($i == $end and $j == $end) {
        return ($matrix[$i][$j], @path, $matrix[$i][$j]);
    }
    elsif ($j > $end) {
        return ('inf', @path);
    }

    my $item = $matrix[$i][$j];

    my @paths;
    if ($i > 0 and $last ne 'down') {
        push @paths, [path($i - 1, $j, 'up', @path, $item)];
    }

    push @paths, [path($i, $j + 1, 'ok', @path, $item)];

    if ($i < $end and $last ne 'up') {
        push @paths, [path($i + 1, $j, 'down', @path, $item)];
    }

    my $min = 'inf';

    foreach my $group (@paths) {
        my ($sum, @p) = @{$group};

        if ($sum < $min) {
            $min  = $sum;
            @path = @p;
        }
    }

    ($min + $item, @path);
}

my ($sum, @path) = path(0, 0, 'ok');

say "Cost: $sum";       #=> Cost: 1363
say "Path: [@path]";    #=> Path: [131 21 96 342 4 103 18 150 111 56 331]
