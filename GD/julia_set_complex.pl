#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 27 March 2016
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

    ##my $maxIter = int(rand(200))+50;
    my $maxIter = 50;

    ##my ($cx, $cy) = (-rand(1), rand(1));
    ##my ($cx, $cy) = (1-rand(2), 1-rand(2));         # cool
    my ($cx, $cy) = (1 - rand(2), rand(1));    # nice
    ##my ($cx, $cy) = (1 - rand(2), 2 - rand(3));
    ##my ($cx, $cy) = ((-1)**((1,2)[rand(2)]) * rand(2), (-1)**((1,2)[rand(2)]) * rand(2));

    my $color = Imager::Color->new('#000000');

    foreach my $x (0 .. $w - 1) {
        foreach my $y (0 .. $h - 1) {
            my $i = iterate(
                3/2 * (2*($x+1) - $w) / ($w * $zoom) + $moveX,
                1/1 * (2*($y+1) - $h) / ($h * $zoom) + $moveY,
                $cx, $cy, $maxIter
            );
            $color->set(hsv => [$i / $maxIter * 360 - 120, 1, $i]);
            $img->setpixel(x => $x, y => $y, color => $color);
        }
    }

    print "Writing new image...\n";
    $img->write(file => "i=$maxIter;c=$cx+$cy.png");
}

__END__
__C__

#include <complex.h>

int iterate(double zx, double zy, double cx, double cy, int i) {
    double complex z = zx + zy * I;
    double complex c = cx + cy * I;
    while (cabs(z) < 2 && --i) {
        z = z*z + c;
        //z = z * cexp(z) + c;
        //z = ccosh(z) + c;
        //z = z * csinh(z) + c;
        //z = z * ccosh(z) + c;
        //z = clog(csinh(z)) + c;
        //z = csqrt(cexp(z) + ccosh(z)) + c;
    }
    return i;
}
