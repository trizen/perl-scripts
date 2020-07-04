#!/usr/bin/perl

# Draw a HSV color wheel.

# Algorithm from:
#   https://rosettacode.org/wiki/Color_wheel

use 5.010;
use strict;
use warnings;

use Imager;
use Math::GComplex qw(cplx i);

my ($width, $height) = (300, 300);
my $center = cplx($width / 2, $height / 2);

my $img = Imager->new(xsize => $width,
                      ysize => $height);

my $pi = atan2(0, -1);

foreach my $y (0 .. $height - 1) {
    foreach my $x (0 .. $width - 1) {

        my $vector    = $center - $x - $y * i;
        my $magnitude = 2 * abs($vector) / $width;
        my $direction = ($pi + atan2($vector->real, $vector->imag)) / (2 * $pi);

        $img->setpixel(
            x     => $x,
            y     => $y,
            color => {hsv => [360 * $direction, $magnitude, $magnitude < 1 ? 1 : 0]}
        );
    }
}

$img->write(file => 'color_wheel.png');
