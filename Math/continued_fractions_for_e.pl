#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 10 May 2016
# Website: https://github.com/trizen

# Continued fractions for Euler's number "e".

use 5.010;
use strict;

sub e_1 {
    my ($i, $limit) = @_;
    $limit > 0 ? ($i / ($i + e_1($i + 1, $limit - 1))) : 0;
}

sub e_2 {
    my ($i, $limit) = @_;
    $limit > 0 ? 1 / (1 + 1 / (2 * $i + 1 / (1 + e_2($i + 1, $limit - 1)))) : 0;
}

say 1 + 1 / e_1(1, 100);    # very fast convergence
say 2 + e_2(1, 100);        # extremely fast convergence
