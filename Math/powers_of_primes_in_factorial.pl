#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 25 August 2016
# Website: https://github.com/trizen

# A simple function that returns the power of a given prime in the factorial of a number.

# For example:
#
#   factorial_power(100, 3) = 48
#
# because 100! contains 48 factors of 3.

use 5.010;
use strict;
use warnings;

sub factorial_power {
    my ($n, $p) = @_;

    my $count = 0;
    my $ppow  = $p;

    while ($ppow <= $n) {
        $count += int($n / $ppow);
        $ppow *= $p;
    }

    return $count;
}

say factorial_power(100, 3);    #=> 48
