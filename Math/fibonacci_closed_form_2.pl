#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 29 October 2015
# Website: https://github.com/trizen

# A very simple and fast closed-form to the Fibonacci sequence

use 5.010;
use strict;
use warnings;

sub fib {
    my ($n) = @_;

    state $S = sqrt(1.25) + 0.5;
    state $T = sqrt(1.25) - 0.5;
    state $W = $S + $T;

    ($S**$n - (-$T)**($n)) / $W;
}

for my $n (1 .. 20) {
    say "F($n) = ", fib($n);
}
