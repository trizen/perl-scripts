#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 20 January 2017
# https://github.com/trizen

# Generation of the Sierpinski triangle,
# by plotting the values of the function
#
#   f(n) = n AND n^2
#

# See also:
#   https://oeis.org/A213541
#   https://en.wikipedia.org/wiki/Sierpinski_triangle

use 5.010;
use strict;
use warnings;

use Imager;

my $size   = 1300;
my $factor = 100;
my $red    = Imager::Color->new('#ff0000');

my $img = Imager->new(xsize => $size,
                      ysize => $size);

foreach my $n (1 .. $size * $factor) {
    $img->setpixel(
                   x     => $n / $factor,
                   y     => $size - ($n & ($n * $n)) / $factor,
                   color => $red
                  );
}

$img->write(file => 'sierpinski_triangle.png');
