#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 27 March 2016
# Website: https://github.com/trizen

# Generate a Julia set, using Will Braswell's "MathPerl::Fractal::Julia" RPerl module.

use 5.010;
use strict;
use warnings;

use Imager;
use MathPerl::Fractal::Julia;

my ($w, $h) = (800, 600);
my $maxIter = 250;

my $cx = -0.7;
my $cy = 0.27015;

my $matrix = MathPerl::Fractal::Julia::julia_escape_time(
    $cx, $cy, $w, $h, $maxIter, -2.5, 1.0, -1.0, 1.0, 0,
);

my $img = Imager->new(xsize => $w, ysize => $h, channels => 3);
my $color = Imager::Color->new('#000000');

my $y = 0;
foreach my $row (@{$matrix}) {
    my $x = 0;
    foreach my $pixel (@{$row}) {
        my $i = $maxIter - $pixel / 255 * $maxIter;
        $color->set(hsv => [$i / $maxIter * 360, 1, $i]);
        $img->setpixel(x => $x, y => $y, color => $color);
        ++$x;
    }
    ++$y;
}

$img->write(file => "julia_set.png");
