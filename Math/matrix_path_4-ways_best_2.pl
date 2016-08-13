#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13 August 2016
# Website: https://github.com/trizen

# In the 5 by 5 matrix below, the minimal path sum from the top left
# to the bottom right, by moving left, right, up, and down, is equal to 2297.

# Problem from: https://projecteuler.net/problem=83

# (this algorithm is scalable only up to 7x7 matrices)

use 5.010;
use strict;
use warnings;

use Memoize qw(memoize);

my @matrix = (
              [131, 673, 234, 103, 18],
              [201, 96,  342, 965, 150],
              [630, 803, 746, 422, 111],
              [537, 699, 497, 121, 956],
              [805, 732, 524, 37,  331],
             );

memoize('path');
my $end = $#matrix;

sub path {
    my ($i, $j, $seen) = @_;

    my @seen = split(' ', $seen);

    my $valid = sub {
        my %seen;
        @seen{@seen} = ();
        not exists $seen{"$_[0]:$_[1]"};
    };

    if ($i >= $end and $j >= $end) {
        return $matrix[$i][$j];
    }

    my @points;

    if ($j < $end and $valid->($i, $j + 1)) {
        push @points, [$i, $j + 1];
    }

    if ($i > 0 and $valid->($i - 1, $j)) {
        push @points, [$i - 1, $j];
    }

    if ($j > 0 and $valid->($i, $j - 1)) {
        push @points, [$i, $j - 1];
    }

    if ($i < $end and $valid->($i + 1, $j)) {
        push @points, [$i + 1, $j];
    }

    my $min = 'inf';
    my $snn = join(' ', sort (@seen, map { join(':', @$_) } @points));

    foreach my $point (@points) {
        my $sum = path(@$point, $snn);
        $min = $sum if $sum < $min;
    }

    $min + $matrix[$i][$j];
}

say path(0, 0, '');
