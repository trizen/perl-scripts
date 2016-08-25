#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13 August 2016
# Website: https://github.com/trizen

# Transform a regular image into a circle mozaic image.

use 5.010;
use strict;
use warnings;

use Imager;

my $radius = 4;
my $space  = 3;

sub image2mozaic {
    my ($img, $outfile) = @_;

    my $width  = $img->getwidth;
    my $height = $img->getheight;

    my $thumb = $img->scale(scalefactor => 1 / ($radius * $space));

    my $thumb_width  = $thumb->getwidth;
    my $thumb_height = $thumb->getheight;

    my @matrix;
    foreach my $y (0 .. $thumb_height - 1) {
        push @matrix, [map {
                [$thumb->getpixel(y => $y, x => $_)->rgba]
        } (0 .. $thumb_width - 1)];
    }

    my $scale_x = int($width / $thumb_width);
    my $scale_y = int($height / $thumb_height);

    my $mozaic = Imager->new(
                             xsize    => $scale_x * $thumb_width,
                             ysize    => $scale_y * $thumb_height,
                             channels => 3,
                            );

    my $color = Imager::Color->new(0, 0, 0);

    foreach my $i (0 .. $#matrix) {
        my $row = $matrix[$i];
        foreach my $j (0 .. $#{$row}) {
            $color->set(@{$row->[$j]});
            $mozaic->circle(
                            r     => $radius,
                            x     => int($radius + $j * $scale_x + rand($space)),
                            y     => int($radius + $i * $scale_y + rand($space)),
                            color => $color,
                           );
        }
    }

    $mozaic->write(file => $outfile);
}

my $file = shift(@ARGV) // die "usage: $0 [image]";
my $img = Imager->new(file => $file) // die "can't load image `$file': $!";

image2mozaic($img, 'circle_mozaic.png');
