#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 01 June 2016
# Website: https://github.com/trizen

# A simple check to determine if a given number n is a perfect power of k.

use 5.010;
use strict;
use warnings;

use ntheory qw(factor);
use List::Util qw(all);

sub is_perfect_power {
    my ($n, $k) = @_;

    my %table;
    ++$table{$_} for factor($n);

    all { $table{$_} % $k == 0 } keys(%table);
}

for my $i (1 .. 1000) {
    say $i if is_perfect_power($i, 3);    # cubes
}
