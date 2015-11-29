#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 29 November 2015
# Website: https://github.com/trizen

# Highlight multiples inside the Pascal's triangle.

use 5.010;
use strict;
use warnings;

use Imager qw();
use ntheory qw(binomial);

my $div  = 3;      # highlight multiples of this integer
my $size = 243;    # the size of the triangle

my $img = Imager->new(xsize => $size * 2, ysize => $size);

my $black = Imager::Color->new('#000000');
my $red   = Imager::Color->new('#ff00000');

$img->box(filled => 1, color => $black);

sub pascal {
    my ($rows) = @_;

    for my $n (1 .. $rows - 1) {
        my $i = 0;
        for my $elem (map { binomial(2 * $n, $_) } 0 .. 2 * $n) {
            if ($elem % $div == 0) {
                $img->setpixel(x => $rows - $n + $i++, y => $n, color => $black);
            }
            else {
                $img->setpixel(x => $rows - $n + $i++, y => $n, color => $red);
            }
        }
    }
}

pascal($size);

$img->write(file => "pascal_s_triangle.png");
