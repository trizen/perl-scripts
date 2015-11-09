#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 09 November 2015
# Website: https://github.com/trizen

# Square roots as continued fractions
# See: https://en.wikipedia.org/wiki/Continued_fraction#Generalized_continued_fraction_for_square_roots

use 5.010;
use strict;
use warnings;

no warnings 'recursion';

sub square_root {
    my ($n, $precision) = @_;
    $precision > 0 ? ($n - 1) / (2 + square_root($n, $precision - 1)) : 0;
}

for my $i (1 .. 10) {
    printf("sqrt(%2d) = %s\n", $i, 1 + square_root($i, 1000));
}
