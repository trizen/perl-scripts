#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 24 May 2017
# https://github.com/trizen

# Generates an interesting pattern.

use 5.010;
use strict;
use warnings;

use Imager;

my $size = 1000;
my $img = Imager->new(xsize => $size, ysize => $size);

foreach my $x (1 .. $size) {
    foreach my $y (1 .. $size) {
        if (($x * $y) % (int(sqrt($x)) + int(sqrt($y))) == 0) {
            $img->setpixel(x => $x - 1, y => $y - 1, color => 'red');
        }
    }
}

$img->write(file => 'box_pattern.png');
