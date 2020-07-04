#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 10 May 2016
# Website: https://github.com/trizen

# Continued fractions for PI.
# Inspired by: https://www.youtube.com/watch?v=fd39yK2GZSA

use 5.010;
use strict;

sub pi_1 {
    my ($i, $limit) = @_;
    $limit > 0 ? ($i**2 / (2 + pi_1($i + 2, $limit - 1))) : 0;
}

sub pi_2 {
    my ($i, $limit) = @_;
    $limit > 0 ? ($i**2 / (2 * $i + 1 + pi_2($i + 1, $limit - 1))) : 0;
}

sub pi_3 {
    my ($i, $limit) = @_;
    $limit > 0 ? ((2 * $i + 1)**2 / (6 + pi_3($i + 1, $limit - 1))) : 0;
}

say 4 / (1 + pi_1(1, 100000));    # slow convergence
say 4 / (1 + pi_2(1, 100));       # fast convergence
say 3 + pi_3(0, 100000);          # slow convergence
