#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 17 August 2016
# Website: https://github.com/trizen

# Find the area of a triangle where all three sides are known, using Heron's Formula.

use 5.010;
use strict;
use warnings;

sub triangle_area {
    my ($x, $y, $z) = @_;
    my $s = ($x + $y + $z) / 2;
    sqrt($s * ($s - $x) * ($s - $y) * ($s - $z));
}

say triangle_area(5, 5, 6);
