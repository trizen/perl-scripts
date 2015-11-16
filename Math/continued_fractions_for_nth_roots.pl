#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 16 November 2015
# Website: https://github.com/trizen

# Nth roots as continued fractions (based on square roots)
# See: https://en.wikipedia.org/wiki/Continued_fraction#Generalized_continued_fraction_for_square_roots

use 5.010;
use strict;
use warnings;

no warnings 'recursion';

sub square_root {
    my ($n, $precision) = @_;

    $precision > 0
      ? ($n - 1) / (2 + square_root($n, $precision - 1))
      : 0;
}

sub nth_root {
    my ($n, $x) = @_;

    for (1 .. $n-1) {
        $x = 1 + square_root($x, 10000);
    }

    $x**(2**int($n - 1) / $n);
}

say nth_root(3,    125);
say nth_root(3,    64);
say nth_root(5,    7776);
say nth_root(2.42, 12**2.42);
say nth_root(5.23, 3.21**5.23);
