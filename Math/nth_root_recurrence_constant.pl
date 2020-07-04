#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 10 May 2016
# Website: https://github.com/trizen

# Compute the nth root recurrence constant (n * (n * (n * (n * ...)^(1/4))^(1/3))^(1/2))
# See also: https://en.wikipedia.org/wiki/Somos%27_quadratic_recurrence_constant

use 5.010;
use strict;

sub root_const {
    my ($n, $limit) = @_;
    $limit > 0 ? ($n * root_const($n+1, $limit-1))**(1/$n) : 1;
}

say root_const(1, 30000);
