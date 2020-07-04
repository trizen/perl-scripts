#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 08 August 2017
# https://github.com/trizen

# Plotting of the terms in the series:
#
#   zeta(1/2 + s*i) = Sum_{n>=1} 1/(n^(1/2 + s*i))
#

# where we have the identity:
#   1/(n^(1/2 + s*i)) = (cos(log(n) * s) - i*sin(log(n) * s)) / sqrt(n)

use 5.010;
use strict;
use warnings;

use Imager;

my $red = Imager::Color->new('#ff0000');

my $size = 1000;
my $img = Imager->new(xsize => $size,
                      ysize => $size);

my $s = 14.134725142;

foreach my $n (1 .. 3000) {

    my ($x, $y) = (
         cos(log($n) * $s) / sqrt($n),
        -sin(log($n) * $s) / sqrt($n),
    );

    $img->setpixel(
                   x     => ($size / 2 + $size / 2 * $x),
                   y     => ($size / 2 + $size / 2 * $y),
                   color => $red,
                  );
}

$img->write(file => 'zeta_real_half.png');
