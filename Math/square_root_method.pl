#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 01 October 2016
# Website: https://github.com/trizen

# Approximate the square root of a number.

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(:overload);

sub square_root {
    my ($n) = @_;

    my $eps = 10**-($Math::AnyNum::PREC >> 2);

    my $m = $n;
    my $r = 0.0;

    while (abs($m - $r) > $eps) {
        $m = ($m + $r) / 2;
        $r = $n / $m;
    }

    $r;
}

say square_root(1234);
