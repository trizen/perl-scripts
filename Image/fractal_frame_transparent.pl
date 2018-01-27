#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 27 January 2018
# https://github.com/trizen

# Adds a transparent Mandelbrot-like fractal frame around the edges of an image.

use 5.020;
use strict;
use warnings;

use feature qw(lexical_subs);
use experimental qw(signatures);

use Imager;
use Math::GComplex qw(cplx);

sub complex_transform ($file) {

    my $img = Imager->new(file => $file);

    my $width  = $img->getwidth;
    my $height = $img->getheight;

    my $max_iter = 10;

    my sub mandelbrot ($x, $y) {

        my $z = cplx(
            (2 * $x - $width) / $width,
            (2 * $y - $height) / $height,
        );

        my $c = $z;
        my $i = $max_iter;

        while (abs($z) < 2 and --$i) {
            $z = $z**5 + $c;
        }

        ($max_iter - $i) / $max_iter;
    }

    foreach my $y (0 .. $height - 1) {
        foreach my $x (0 .. $width - 1) {

            my $i = mandelbrot($x, $y);

            my $pixel = $img->getpixel(x => $x, y => $y);
            my ($red, $green, $blue, $alpha) = $pixel->rgba();

            $red   *= $i;
            $green *= $i;
            $blue  *= $i;
            $alpha *= $i;

            $pixel->set($red, $green, $blue, $alpha);

            $img->setpixel(
                x     => $x,
                y     => $y,
                color => $pixel,
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
