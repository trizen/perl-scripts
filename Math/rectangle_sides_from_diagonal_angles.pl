#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 22 January 2018
# https://github.com/trizen

# Formula for finding the smallest integer sides of a rectangle, given the internal angles of its diagonal.

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(:trig :overload);

sub diagonal_angles ($x, $y, $z) {
    (
        acos(($x**2 + $z**2 - $y**2) / (2 * $x * $z)),
        acos(($y**2 + $z**2 - $x**2) / (2 * $y * $z)),
    );
}

sub rectangle_side_from_angle ($theta) {
    sqrt((cos($theta)**2)->rat_approx->numerator);
}

my $x = 43;                         # side 1
my $y = 97;                         # side 2
my $z = sqrt($x**2 + $y**2);        # diagonal

my ($a1, $a2) = diagonal_angles($x, $y, $z);

say "The internal diagonal angles:";
say '  ', rad2deg($a1);     #=> 66.0923395058274991877532084833790002675999587054
say '  ', rad2deg($a2);     #=> 23.9076604941725008122467915166209997324000412946

say "\nThe smallest side lenghts matching the internal angles:";
say rectangle_side_from_angle($a1);         #=> 43
say rectangle_side_from_angle($a2);         #=> 97
