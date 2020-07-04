#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 08 August 2016
# Website: https://github.com/trizen

# Solve a magic 5-gon ring.
# See: https://projecteuler.net/problem=68

use 5.014;
use ntheory qw(forperm);

my $max  = '';
my @nums = (1 .. 10);

forperm {
    my @d = @nums[@_];

    my $i = $d[0] + $d[1] + $d[2];
    my $j = $d[3] + $d[2] + $d[4];
    my $k = $d[5] + $d[4] + $d[6];
    my $l = $d[7] + $d[6] + $d[8];
    my $m = $d[9] + $d[8] + $d[1];

    if (    $d[0] < $d[3]
        and $d[0] < $d[5]
        and $d[0] < $d[7]
        and $d[0] < $d[9]
        and $i == $j
        and $i == $k
        and $i == $l
        and $i == $m
    ) {
        printf(
            "(%2d %2d %2d | %2d %2d %2d | %2d %2d %2d | %2d %2d %2d | %2d %2d %2d) = %2d\n",

            $d[0], $d[1], $d[2],
            $d[3], $d[2], $d[4],
            $d[5], $d[4], $d[6],
            $d[7], $d[6], $d[8],
            $d[9], $d[8], $d[1],

            $i
        );
    }
} scalar(@nums);
