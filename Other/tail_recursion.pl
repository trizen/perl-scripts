#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 04 January 2017
# https://github.com/trizen

# A simple example for tail-recursion in Perl.

use 5.016;
use strict;
use warnings;

sub factorial {
    my ($n, $fac) = @_;
    return $fac if $n == 0;
    @_ = ($n-1, $n*$fac);
    goto __SUB__;
}

say factorial(5, 1);
