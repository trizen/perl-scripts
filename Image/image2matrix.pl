#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13 August 2016
# Website: https://github.com/trizen

# Transform an image into a matrix of RGB values.

use 5.010;
use strict;
use warnings;

use Imager;

my $file = shift(@ARGV) // die "usage: $0 [image]";
my $img = Imager->new(file => $file);

foreach my $y (0 .. $img->getheight - 1) {
    say join(
        ',',
        map {
            my $color = $img->getpixel(y => $y, x => $_);
            my ($r, $g, $b) = $color->rgba;

            my $rgb = $r;
            $rgb = ($rgb << 8) + $g;
            $rgb = ($rgb << 8) + $b;

            $rgb
          } (0 .. $img->getwidth - 1)
    );
}
