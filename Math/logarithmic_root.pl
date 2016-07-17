#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 17 July 2016
# Website: https://github.com/trizen

# Logarithmic root of n.
# Solves c = x^x, where "c" is known.
# (based on Newton's method for nth-root)

# Example: 100 = x^x
#          x = lgrt(100)
#          x =~ 3.59728502354042

use 5.010;
use strict;
use warnings;

sub lgrt {
    my ($c, $p) = @_;

    my $d = log($c);

    my $x = 1;
    my $y = 0;

    while (abs($x - $y) > $p) {
        $y = $x;
        $x = ($x + $d) / (1 + log($x));
    }

    $x;
}

say lgrt(100, 1e-15);
