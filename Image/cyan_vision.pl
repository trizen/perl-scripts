#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 16 November 2016
# Website: https://github.com/trizen

# Redraws each pixel as a cyan colored circle.

# WARNING: this process is *very* slow for large images.

use 5.010;
use strict;
use warnings;

use Imager;
use List::Util qw(max);

my @matrix;

{
    my $img = Imager->new(file => shift(@ARGV))
      || die die "usage: $0 [image]\n";

    my $height = $img->getheight - 1;
    my $width  = $img->getwidth - 1;

    foreach my $y (0 .. $height) {
        push @matrix, [
            map {
                my ($r, $g, $b) = $img->getpixel(y => $y, x => $_)->rgba;

                my $rgb = $r;
                $rgb = ($rgb << 8) + $g;
                $rgb = ($rgb << 8) + $b;

                $rgb
              } (0 .. $width)
        ];
    }
}

my $max_color    = 2**16 - 1;                          # normal color is: 2**24 - 1
my $scale_factor = 3;                                  # the scaling factor does not affect the performance
my $radius       = $scale_factor / atan2(0, -'inf');
my $space        = $radius / 2;

my $img = Imager->new(
                      xsize    => @{$matrix[0]} * $scale_factor,
                      ysize    => @matrix * $scale_factor,
                      channels => 3,
                     );

my $max = max(map { @$_ } @matrix);

foreach my $i (0 .. $#matrix) {
    my $row = $matrix[$i];
    foreach my $j (0 .. $#{$row}) {
        $img->circle(
                     r     => $radius,
                     x     => $j * $scale_factor + $radius + $space,
                     y     => $i * $scale_factor + $radius + $space,
                     color => sprintf("#%06x", $row->[$j] / $max * $max_color),
                    );
    }
}

$img->write(file => 'cyan_image.png');
