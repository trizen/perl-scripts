#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 07 March 2016
# Edit: 25 January 2018
# Website: https://github.com/trizen

# See also:
#   https://en.wikipedia.org/wiki/Julia_set
#   https://trizenx.blogspot.ro/2016/05/julia-set.html

use 5.010;
use strict;
use warnings;

use Imager;
use Math::GComplex qw(cplx);

my($w, $h, $zoom) = (1000, 1000, 0.7);

my $img   = Imager->new(xsize => $w, ysize => $h, channels => 3);
my $color = Imager::Color->new('#000000');

my $I = 255;
my $L = 2;
my $c = cplx(-0.7, 0.27015);

my ($moveX, $moveY) = (0, 0);

foreach my $x (0 .. $w - 1) {
    foreach my $y (0 .. $h - 1) {

        my $z = cplx(
            (2 * $x - $w) / ($w * $zoom) + $moveX,
            (2 * $y - $h) / ($h * $zoom) + $moveY,
        );

        my $i = $I;
        while (abs($z) < $L and --$i) {
            $z = $z*$z + $c;
        }

        $color->set(hsv => [$i / $I * 360 - 120, 1, $i / $I]);
        $img->setpixel(x => $x, y => $y, color => $color);
    }
}

$img->write(file => 'julia_set.png');
