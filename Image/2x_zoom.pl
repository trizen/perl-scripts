#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 11 March 2017
# https://github.com/trizen

# A simple gap-filling algorithm for applying a 2x zoom to an image.

use 5.010;
use strict;
use warnings;

use Imager;
use List::Util qw(sum);

my $file = shift(@ARGV) // die "usage: $0 [image]\n";

my $img = Imager->new(file => $file)
  or die Imager->errstr();

my $width  = $img->getwidth;
my $height = $img->getheight;

my @matrix;
foreach my $y (0 .. $height - 1) {
    foreach my $x (0 .. $width - 1) {
        $matrix[$y][$x] = $img->getpixel(x => $x, y => $y);
    }
}

my $out_img = Imager->new(xsize => 2 * $width,
                          ysize => 2 * $height);

sub gap_color {
    my ($x, $y) = @_;

    my @neighbors;

    if ($y > 0) {

        # Top neighbor
        if ($x < $width) {
            push @neighbors, $matrix[$y - 1][$x];
        }

        # Top-right neighbor
        if ($x < $width - 1) {
            push @neighbors, $matrix[$y - 1][$x + 1];
        }

        # Top-left neighbor
        if ($x > 0) {
            push @neighbors, $matrix[$y - 1][$x - 1];
        }
    }

    if ($y < $height - 1) {

        # Bottom neighbor
        if ($x < $width) {
            push @neighbors, $matrix[$y + 1][$x];
        }

        # Bottom-right neighbor
        if ($x < $width - 1) {
            push @neighbors, $matrix[$y + 1][$x + 1];
        }

        # Bottom-left neighbor
        if ($x > 0) {
            push @neighbors, $matrix[$y + 1][$x - 1];
        }
    }

    if ($y < $height) {

        # Left neighbor
        if ($x > 0) {
            push @neighbors, $matrix[$y][$x - 1];
        }

        # Right neighbor
        if ($x < $width - 1) {
            push @neighbors, $matrix[$y][$x + 1];
        }
    }

    # Get the RGBA colors
    my @colors = map { [$_->rgba] } @neighbors;

    my @red   = map { $_->[0] } @colors;
    my @blue  = map { $_->[1] } @colors;
    my @green = map { $_->[2] } @colors;
    my @alpha = map { $_->[3] } @colors;

#<<<
    # Compute the average gap-filling color
    my @gap_color = (
        sum(@red  ) / @red,
        sum(@blue ) / @blue,
        sum(@green) / @green,
        sum(@alpha) / @alpha,
    );
#>>>

    return \@gap_color;
}

foreach my $y (0 .. $#matrix) {
    foreach my $x (0 .. $#{$matrix[$y]}) {
#<<<
        # Fill the gaps
        $out_img->setpixel(x => 2 * $x,     y => 2 * $y,     color => $matrix[$y][$x]);
        $out_img->setpixel(x => 2 * $x + 1, y => 2 * $y + 1, color => gap_color($x + 1, $y + 1));
        $out_img->setpixel(x => 2 * $x + 1, y => 2 * $y,     color => gap_color($x + 1, $y    ));
        $out_img->setpixel(x => 2 * $x,     y => 2 * $y + 1, color => gap_color($x,     $y + 1));
#>>>
    }
}

$out_img->write(file => '2x_zoom.png');
