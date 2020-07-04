#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 30 October 2017
# https://github.com/trizen

# Generation of a colored-table of values `n^k (mod m)`, where `n` are the rows and `k` are the columns.

use 5.010;
use strict;
use warnings;

use Imager;

my $size = 1000;
my $red  = Imager::Color->new('#ff0000');

my $img = Imager->new(xsize => $size,
                      ysize => $size);

my $mod = 7;

my @colors = map {
    Imager::Color->new(sprintf("#%x", rand(256**3)))
} 1 .. $mod;

foreach my $n (0 .. $size - 1) {
    foreach my $k (0 .. $size - 1) {
        $img->setpixel(x => $k, y => $n, color => $colors[($n ^ $k) % $mod]);
    }
}

$img->write(file => 'xor_pattern.png');
