#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 30 April 2019
# https://github.com/trizen

# Given an array of `n` elements, generate all the possible consecutive partitions (with no swaps and go gaps).

# For example, given the array [1,2,3,4,5], there are 16 different ways to
# subdivide the array (using all of its elements in their original order):
#
#   [[1, 2, 3, 4, 5]]
#   [[1], [2, 3, 4, 5]]
#   [[1, 2], [3, 4, 5]]
#   [[1, 2, 3], [4, 5]]
#   [[1, 2, 3, 4], [5]]
#   [[1], [2], [3, 4, 5]]
#   [[1], [2, 3], [4, 5]]
#   [[1], [2, 3, 4], [5]]
#   [[1, 2], [3], [4, 5]]
#   [[1, 2], [3, 4], [5]]
#   [[1, 2, 3], [4], [5]]
#   [[1], [2], [3], [4, 5]]
#   [[1], [2], [3, 4], [5]]
#   [[1], [2, 3], [4], [5]]
#   [[1, 2], [3], [4], [5]]
#   [[1], [2], [3], [4], [5]]
#

# In general, for a given array with `n` elements, there are `2^(n-1)` possibilities.

use 5.014;
use strict;
use warnings;

use ntheory qw(forcomb vecsum);

sub split_at_indices {
    my ($array, $indices) = @_;

    my $i = 0;
    my @parts;

    foreach my $j (@$indices) {
        push @parts, [@{$array}[$i .. $j]];
        $i = $j + 1;
    }

    return @parts;
}

sub consecutive_partitions {
    my (@array) = @_;

    my @subsets;

    foreach my $k (0 .. @array) {
        forcomb {
            my @t = split_at_indices(\@array, \@_);
            if (vecsum(map { scalar(@$_) } @t) == @array) {
                push @subsets, \@t;
            }
        } scalar(@array), $k;
    }

    return @subsets;
}

my @subsets = consecutive_partitions(1, 2, 3, 4, 5);

foreach my $subset (@subsets) {
    say join(', ', map { "[@$_]" } @$subset);
}
