#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 26 March 2016
# Website: https://github.com/trizen

# Generate 100 random Julia sets.
# Formula: f(z) = z^2 + c

# See also: https://en.wikipedia.org/wiki/Julia_set
#           http://rosettacode.org/wiki/Julia_set

use strict;
use warnings;

use Imager;
use Inline 'C';

for (1 .. 100) {

    my ($w, $h) = (800, 600);

    my $zoom  = 1;
    my $moveX = 0;
    my $moveY = 0;

    my $img = Imager->new(xsize => $w, ysize => $h, channels => 3);

    #my $maxIter = int(rand(200))+50;
    my $maxIter = 50;

    #my ($cX, $cY) = (-rand(1), rand(1));
    #my ($cX, $cY) = (1-rand(2), 1-rand(2));        # cool
    my ($cX, $cY) = (1 - rand(2), rand(1));         # nice

    my $color = Imager::Color->new('#000000');

    foreach my $x (0 .. $w - 1) {
        foreach my $y (0 .. $h - 1) {
            my $zx = 3/2 * (2*($x+1) - $w) / ($w * $zoom) + $moveX;
            my $zy = 1/1 * (2*($y+1) - $h) / ($h * $zoom) + $moveY;
            my $i  = iterate($zx, $zy, $cX, $cY, $maxIter);
            $color->set(hsv => [$i / $maxIter * 360, 1, $i]);
            $img->setpixel(x => $x, y => $y, color => $color);
        }
    }

    $img->write(file => "i=$maxIter;x=$cX;y=$cY.png");
}

__END__
__C__

int iterate(double zx, double zy, double cX, double cY, int i) {
    double tmp1;
    double tmp2;

    while(1) {
        tmp1 = zx*zx;
        tmp2 = zy*zy;

        if (!((tmp1 + tmp2 < 4) && (--i > 0))) {
            break;
        }

        zy = 2 * zx*zy + cY;
        zx = tmp1 - tmp2 + cX;
    }
    return i;
}
