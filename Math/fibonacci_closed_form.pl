#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 29 October 2015
# Website: https://github.com/trizen

# A simple closed-form to the Fibonacci sequence

use 5.010;
use strict;
use warnings;

sub fib {
    my ($n) = @_;

    state $S  = sqrt(5);
    state $T  = ((1 + $S) / 2);
    state $U  = (2 / (1 + $S));
    state $PI = atan2(0, -'inf');

    ($T**$n - ($U**$n * cos($PI * $n))) / $S;
}

for my $n (1 .. 20) {
    say "F($n) = ", fib($n);
}
