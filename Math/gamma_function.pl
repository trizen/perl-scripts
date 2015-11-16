#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 17 November 2015
# Website: https://github.com/trizen

# The gamma function implemented as an improper integral
# See: https://en.wikipedia.org/wiki/Gamma_function

use 5.010;
use strict;
use warnings;

sub gamma {
    my ($n) = @_;

    my $sum = 0;
    for my $t (0 .. 1000) {
        $sum += $t**($n - 1) * exp(-$t);
    }

    return $sum;
}

for my $n (1 .. 20) {
    printf "gamma(%2d) = %.24f\n", $n, gamma($n);
}
