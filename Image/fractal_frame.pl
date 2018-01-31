#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 25 January 2018
# https://github.com/trizen

# Adds a Mandelbrot-like fractal frame around the edges of an image.

use 5.020;
use strict;
use warnings;

use feature qw(lexical_subs);
use experimental qw(signatures);

use Imager;
use Math::GComplex qw(cplx);

sub complex_transform ($file) {

    my $img   = Imager->new(file => $file);
    my $black = Imager::Color->new('#000000');

    my $width  = $img->getwidth;
    my $height = $img->getheight;

    my sub mandelbrot ($x, $y) {

        my $z = cplx(
            (2 * $x - $width)  / $width,
            (2 * $y - $height) / $height,
        );

        my $c = $z;
        my $i = 10;

        while (abs($z) < 2 and --$i) {
            $z = $z**5 + $c;
        }

        return $i;
    }

    foreach my $y (0 .. $height - 1) {
        foreach my $x (0 .. $width - 1) {

            next if (mandelbrot($x, $y) == 0);

            $img->setpixel(
                           x     => $x,
                           y     => $y,
                           color => $black,
                          );
        }
    }

    return $img;
}

sub usage {
    die "usage: $0 [input image] [output image]\n";
}

my $input  = shift(@ARGV) // usage();
my $output = shift(@ARGV) // 'fractal_frame.png';

complex_transform($input)->write(file => $output);
