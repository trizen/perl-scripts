#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 29 July 2017
# https://github.com/trizen

# A high-level algorithm implementation for computing the nth-harmonic number, using perfect powers.

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(:overload idiv);

sub harmonic_numbers_from_powers {
    my ($n) = @_;

    my @seen;
    my $harm = $n <= 0 ? 0 : 1;

    foreach my $k (2 .. $n) {
        if (not exists $seen[$k]) {

            my $p = $k;

            do {
                $seen[$p] = undef;
            } while (($p *= $k) <= $n);

            my $g = idiv($p, $k);
            my $t = idiv($g - 1, $k - 1);

            $harm += $t / $g;
        }
    }

    return $harm;
}

foreach my $i (0 .. 30) {
    printf "%20s / %-20s\n", harmonic_numbers_from_powers($i)->nude;
}
