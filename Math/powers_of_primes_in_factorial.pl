#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 25 August 2016
# Website: https://github.com/trizen

# A simple function that returns the power of a given prime in the factorial of a number.

# For example:
#
#   power(100, 3) = 48
#
# because 100! contains 48 factors of 3.

use 5.010;
use strict;
use warnings;

sub power {
    my ($n, $p) = @_;

    my $s = 0;
    while ($n >= $p) {
        $s += int($n /= $p);
    }

    $s;
}

say power(100, 3);    #=> 48
