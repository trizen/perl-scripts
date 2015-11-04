#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 04 November 2015
# Website: https://github.com/trizen

# Continued fractions

use 5.010;
use strict;
use warnings;

no warnings 'recursion';

sub root2 {
    my ($n) = @_;

    return 0 if $n <= 0;

    1.0/(
        2.0 + root2($n-1)
    )
}

sub e {
    my($i, $n) = @_;

    return 0 if $n >= $i;

    1.0/(
        1.0 + 1.0/(
            2.0*$n + 1.0/(
                1.0 + e($i, $n+1)
            )
        )
    )
}

say 1+root2(100);       # sqrt(2)
say 2+e(100, 1);        # e
