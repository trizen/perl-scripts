#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 27 July 2018
# https://github.com/trizen

# A simple implementation of the nearest-neighbor interpolation algorithm for scalling up an image.

# See also:
#   https://en.wikipedia.org/wiki/Nearest-neighbor_interpolation

use 5.020;
use strict;
use warnings;

use Imager;
use experimental qw(signatures);

sub nearest_neighbor_interpolation ($file, $zoom = 2) {

    my $img = Imager->new(file => $file)
      or die Imager->errstr();

    my $width  = $img->getwidth;
    my $height = $img->getheight;

    my $out_img = Imager->new(xsize => $zoom * $width,
                              ysize => $zoom * $height);

    foreach my $y (0 .. $height - 1) {
        foreach my $x (0 .. $width - 1) {
            my $pixel = $img->getpixel(x => $x, y => $y);
#<<<
            # Fill the gaps
            $out_img->setpixel(x => $zoom * $x,     y => $zoom * $y,     color => $pixel);
            $out_img->setpixel(x => $zoom * $x + 1, y => $zoom * $y + 1, color => $pixel);
            $out_img->setpixel(x => $zoom * $x + 1, y => $zoom * $y,     color => $pixel);
            $out_img->setpixel(x => $zoom * $x,     y => $zoom * $y + 1, color => $pixel);
#>>>
        }
    }

    return $out_img;
}

my $file = shift(@ARGV) // die "usage: $0 [image]\n";
my $img  = nearest_neighbor_interpolation($file, 2);

$img->write(file => "output.png");
