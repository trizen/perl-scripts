#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 08 August 2016
# Website: https://github.com/trizen

# Find the greedy-minimum path from each end of a square matrix.
# Inspired by: https://projecteuler.net/problem=81

# "Path 1" is from the top-left of the matrix, to the bottom-right.
# "Path 2" is from the bottom-right of the matrix, to the top-left.

# "Path 1" moves only right and down.
# "Path 2" moves only left and up.

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

my @path_1;
my @path_2;

{
    my $i = 0;
    my $j = 0;

    push @path_1, $matrix[$i][$j];

    while (1) {

        if (    exists($matrix[$i][$j + 1])
            and exists($matrix[$i + 1])
            and $matrix[$i][$j + 1] < $matrix[$i + 1][$j]) {
            ++$j;
        }
        else {
            ++$i;
        }

        push @path_1, $matrix[$i][$j];

        if ($i == $end and $j == $end) { last }
    }
}

{

    my $i = $end;
    my $j = $end;

    push @path_2, $matrix[$i][$j];

    while (1) {

        if (    $j - 1 >= 0
            and $i - 1 >= 0
            and exists($matrix[$i][$j - 1])
            and exists($matrix[$i - 1])
            and $matrix[$i][$j - 1] < $matrix[$i - 1][$j]) {
            --$j;
        }
        else {
            --$i;
        }

        push @path_2, $matrix[$i][$j];

        if ($i == 0 and $j == 0) { last }
    }

}

say "Path 1: [@path_1]";
say "Path 2: [@path_2]";
