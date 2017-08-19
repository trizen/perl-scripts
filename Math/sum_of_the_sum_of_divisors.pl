#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 19 August 2017
# https://github.com/trizen

# Sum of the sum of divisors, `sigma(k)`, for 1 <= k <= n.

# Algorithm due to Peter Polm (August 18, 2014) (see: A024916).

use 5.010;
use strict;
use warnings;

sub sum_of_sigma {
    my ($n) = @_;

    my $s = 0;
    my $d = 1;
    my $q = $n;

    for (; $d < $q ; ++$d, $q = int($n / $d)) {
        $s += $q * (2 * $d + $q + 1) >> 1;
    }

    $s - $d * ($d * ($d - 1) >> 1) + ($q * ($q + 1) >> 1);
}

say sum_of_sigma(13);       #=> 141
say sum_of_sigma(64);       #=> 3403
say sum_of_sigma(1234);     #=> 1252881
say sum_of_sigma(10**8);    #=> 8224670422194237
