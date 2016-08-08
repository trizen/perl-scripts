#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 08 August 2016
# Website: https://github.com/trizen

# Solve a magic 3-gon ring.
# See: https://projecteuler.net/problem=68

use 5.014;
use ntheory qw(forperm);

my @nums = (1 .. 6);

forperm {
    my @d = @nums[@_];
    my $n = $d[0] + $d[1] + $d[2];

    if (    $d[0] < $d[3]
        and $d[0] < $d[5]
        and $n == $d[3] + $d[2] + $d[4]
        and $n == $d[5] + $d[4] + $d[1]) {
        say "($d[0] $d[1] $d[2] | $d[3] $d[2] $d[4] | $d[5] $d[4] $d[1]) = $n";
    }
} scalar(@nums);
