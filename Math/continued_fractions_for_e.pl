#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 10 May 2016
# Edit: 14 July 2017
# Website: https://github.com/trizen

# Continued fractions for the "e" mathematical constant.

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

sub e_6 {
    my ($i, $n) = @_;

    return 0 if $n >= $i;

    2 / (
        8*($n+1) - 2 + 2 / (
            4*($n+1) + 1 + e_6($i, $n+1)
        )
    );
}

sub e_7 {
    my ($i, $n) = @_;

    return 0 if $n >= $i;

    8 / (
        16*$n + 4 + 8 / (
            8*($n+1) - 2 + e_7($i, $n+1)
        )
    );
}

sub e_8 {
    my ($i, $n) = @_;

    return 0 if $n >= $i;

    1 / (
        4*($n-1) + 1 + 1 / (
            1 + 1/(
                1 + e_8($i, $n+1)
            )
        )
    );
}

sub e_9 {
    my ($i, $n) = @_;

    return 0 if $n >= $i;

    1/(
        2 + 1/(
            4*$n + 1 + 1/(
                -2 + 1/ (
                    -4*$n - 3 + e_9($i, $n+1)
                )
            )
        )
    )
}

my $r = 100;        # number of repetitions

say 1 + 1 / e_1(1, $r);                  # good convergence
say 2 + e_2(1, $r);                      # very fast convergence
say sqrt(1 + 2 / e_3(1, $r));            # very fast convergence
say sqrt(7 + 1 / (2 + (e_4($r, 1))));    # extremely fast convergence (best)
say ((5 + 1/(2 +  e_5($r, 1)))/2);       # extremely fast convergence
say sqrt(7 + 2/(5 + e_6($r, 1)));        # extremely fast convergence
say sqrt(7 + e_7($r, 1));                # very fast convergence
say ((1 + e_8($r, 1))**2);               # very fast convergence
say 3 + 1/(-4 + e_9($r, 1));             # extremely fast convergence
