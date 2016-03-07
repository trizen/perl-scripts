#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 07 March 2016
# Website: https://github.com/trizen

# See: https://en.wikipedia.org/wiki/Julia_set

use strict;
use warnings;

use Imager;

my($w, $h, $zoom) = (800, 600, 1);
my $img = Imager->new(xsize => $w, ysize => $h, channels => 3);

my $maxIter = 255;
my($cX, $cY) = (-0.7, 0.27015);
my ($moveX, $moveY) = (0, 0);

foreach my $x (0 .. $w - 1) {
    foreach my $y (0 .. $h - 1) {
        my $zx = (1.5 * ($x - $w / 2) / (0.5 * $zoom * $w) + $moveX);
        my $zy = (($y - $h / 2) / (0.5 * $zoom * $h) + $moveY);
        my $i = $maxIter;
        for (; $zx**2 + $zy**2 < 4 and $i > 1; --$i) {
            my $tmp = ($zx**2 - $zy**2 + $cX);
            ($zy, $zx) = (2.0 * $zx * $zy + $cY, $tmp);
        }
        my $color = Imager::Color->new(
            hsv => [($i / $maxIter) * 360, 1, $i > 1 ? 1 : 0]
        );
        $img->setpixel(x => $x, y => $y, color => $color);
    }
}

$img->write(file => 'julia_set.png');
