#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 22 January 2018
# https://github.com/trizen

# Formula for finding the smallest integer sides of a rectangle, given one internal angle of its diagonal.

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(:trig :overload);

sub rectangle_sides_from_angle ($theta) {
    tan($theta)->rat_approx->nude;
}

my $x = 43;    # side 1
my $y = 97;    # side 2

my $theta = atan2($x, $y);

say "A rectangle internal diagonal angle:";
say '  ', rad2deg($theta);    #=> 23.9076604941725008122467915166209997324000412946

say "\nThe smallest integer sides matching the internal angle:";
say join(' ', rectangle_sides_from_angle($theta));    #=> 43 97
