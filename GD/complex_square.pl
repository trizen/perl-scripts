#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 07 January 2016
# License: GPLv3
# Website: https://github.com/trizen

# Illustration of the complex square root function

use 5.010;
use strict;
use warnings;

use Imager;
use Math::AnyNum;

my $img = Imager->new(xsize => 2000, ysize => 1500);

my $white = Imager::Color->new('#ffffff');
my $black = Imager::Color->new('#000000');

$img->box(filled => 1, color => $black);

for my $i (1 .. 400) {
    for my $j (1 .. 400) {
        my $x = Math::AnyNum->new_c($i, $j)->sqrt;
        my ($re, $im) = ($x->real->numify, $x->imag->numify);
        $img->setpixel(x => 300 + int(60 * $re), y => 400 + int(60 * $im), color => $white);
    }
}

$img->write(file => 'complex_square.png');
