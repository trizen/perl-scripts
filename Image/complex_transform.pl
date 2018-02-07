#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 31 January 2018
# https://github.com/trizen

# Complex transform of an image, by mapping each pixel position to a complex function.

use 5.020;
use strict;
use warnings;

use feature qw(lexical_subs);
use experimental qw(signatures);

use Imager;
use List::Util qw(min max);
use Math::GComplex qw(cplx);

sub map_range ($this, $in_min, $in_max, $out_min, $out_max) {
    $this =~ /[0-9]/ or return 0;
    ($this - $in_min) * ($out_max - $out_min) / ($in_max - $in_min) + $out_min;
}

sub complex_transform ($file) {

    my $img = Imager->new(file => $file);

    my $width  = $img->getwidth;
    my $height = $img->getheight;

    my @vals;

    foreach my $y (0 .. $height - 1) {
        foreach my $x (0 .. $width - 1) {

            my $z = cplx(
                (2 * $x - $width) / $width,
                (2 * $y - $height) / $height,
            );

            push @vals, [$x, $y, $z->sin->reals];
        }
    }

    my $max_x = max(map { $_->[2] } grep { $_->[2] =~ /[0-9]/ } @vals);
    my $max_y = max(map { $_->[3] } grep { $_->[3] =~ /[0-9]/ } @vals);

    my $min_x = min(map { $_->[2] } grep { $_->[2] =~ /[0-9]/ } @vals);
    my $min_y = min(map { $_->[3] } grep { $_->[3] =~ /[0-9]/ } @vals);

    say "X: [$min_x, $max_x]";
    say "Y: [$min_y, $max_y]";

    my $new_img = Imager->new(
        xsize => $width,
        ysize => $height,
    );

    foreach my $val (@vals) {

        $new_img->setpixel(
            x     => sprintf('%.0f', map_range($val->[2], $min_x, $max_x, 0, $width  - 1)),
            y     => sprintf('%.0f', map_range($val->[3], $min_y, $max_y, 0, $height - 1)),
            color => $img->getpixel(x => $val->[0], y => $val->[1]),
        );
    }

    return $new_img;
}

sub usage {
    die "usage: $0 [input image] [output image]\n";
}

my $input  = shift(@ARGV) // usage();
my $output = shift(@ARGV) // 'complex_transform.png';

complex_transform($input)->write(file => $output);
