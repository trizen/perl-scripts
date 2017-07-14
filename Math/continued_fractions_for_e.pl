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

sub e_3 {
    my ($i, $limit) = @_;
    $limit > 0 ? (1 / (2 * $i + 1 + e_3($i + 1, $limit - 1))) : 0;
}

sub e_4 {
    my ($i, $n) = @_;

    return 0 if $n >= $i;

    1 / (
        1 + 1 / (
            1 + 1 / (
                (3 * $n) + 1 / (
                    (12 * $n + 6) + 1 / (
                        (3 * $n + 2) + e_4($i, $n + 1)
                    )
                )
            )
        )
    );
}

sub e_5 {
    my ($i, $n) = @_;

    return 0 if $n >= $i;

    1 / (
        3 + 1 / (
            2*$n + 1 / (
                3 + 1 / (
                    1 + 1 / (
                        2*$n + 1 / (
                            1 + e_5($i, $n + 1)
                        )
                    )
                )
            )
        )
    );
}

my $r = 100;        # number of repetitions

say 1 + 1 / e_1(1, $r);                  # very fast convergence
say 2 + e_2(1, $r);                      # extremely fast convergence
say sqrt(1 + 2 / e_3(1, $r));            # extremely fast convergence
say sqrt(7 + 1 / (2 + (e_4($r, 1))));    # ultra-fast convergence
say ((5 + 1/(2 +  e_5($r, 1)))/2);       # ultra-fast convergence
