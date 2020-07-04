#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 12 May 2018
# https://github.com/trizen

# Find the smallest solution in positive integers to the Pell equation: x^2 - d*y^2 = 1, where `d` is known.

# See also:
#   https://en.wikipedia.org/wiki/Pell%27s_equation

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(idiv isqrt is_square);

sub solve_pell ($n) {

    return () if is_square($n);

    my $x = isqrt($n);
    my $y = $x;
    my $z = 1;
    my $r = $x + $x;

    my ($f1, $f2) = (1, $x);

    for (; ;) {

        $y = $r * $z - $y;
        $z = idiv($n - $y * $y, $z);
        $r = idiv($x + $y, $z);

        ($f1, $f2) = ($f2, $r * $f2 + $f1);

        if ($z == 1) {

            my $p = 4 * $n * ($f1 * $f1 - 1);

            if (is_square($p)) {
                return ($f1, idiv(isqrt($p), 2 * $n));
            }
        }
    }
}

foreach my $d (1 .. 100) {

    my ($x, $y) = solve_pell($d);

    if (defined($x)) {
        printf("x^2 - %2dy^2 = %2d    minimum solution: x=%15s and y=%15s\n", $d, $x**2 - $d * $y**2, $x, $y);
    }
}
