#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 14 September 2016
# License: GPLv3
# https://github.com/trizen

use strict;
use warnings;

use Imager;

use POSIX qw(ceil);
use ntheory qw(is_prime);

my $limit = 1000;
my $red   = Imager::Color->new('#ff0000');

my $img = Imager->new(xsize => 2 * $limit,
                      ysize => $limit,);

sub get_point {
    my ($n) = @_;

    my $row  = ceil(sqrt($n));
    my $cell = 2 * $row - 1 - $row**2 + $n;

    ($cell, $row);
}

foreach my $n (1 .. $limit**2) {
    if (is_prime($n)) {
        my ($x, $y) = get_point($n);
        $img->setpixel(x => $x, y => $y, color => $red);
    }
}

$img->write(file => 'prime_triangle_90deg.png');
