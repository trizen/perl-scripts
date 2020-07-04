#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 11 March 2017
# https://github.com/trizen

# Julia transform of an image.

# See also:
#   https://en.wikipedia.org/wiki/Julia_set

use 5.010;
use strict;
use warnings;

use Imager;
use Math::GComplex;

my $file = shift(@ARGV) // die "usage: $0 [image]\n";

sub map_val {
    my ($value, $in_min, $in_max, $out_min, $out_max) = @_;

#<<<
    ($value - $in_min)
        * ($out_max - $out_min)
        / ($in_max - $in_min)
    + $out_min;
#>>>
}

my $img = Imager->new(file => $file)
  or die Imager->errstr();

my $width  = $img->getwidth;
my $height = $img->getheight;

sub transform {
    my ($x, $y) = @_;

#<<<
    my $z = Math::GComplex->new(
        (2 * $x - $width ) / $width,
        (2 * $y - $height) / $height,
    );
#>>>

    state $c = Math::GComplex->new(-0.4, 0.6);

    my $i = 10;
    while ($z->abs < 2 and --$i >= 0) {
        $z = $z * $z + $c;
    }

    $z->reals;
}

my @matrix;

my ($min_x, $min_y) = ('inf') x 2;
my ($max_x, $max_y) = (-'inf') x 2;

foreach my $y (0 .. $height - 1) {
    foreach my $x (0 .. $width - 1) {
        my ($new_x, $new_y) = transform($x, $y);

        $matrix[$y][$x] = [$new_x, $new_y];

        if ($new_x < $min_x) {
            $min_x = $new_x;
        }
        if ($new_y < $min_y) {
            $min_y = $new_y;
        }
        if ($new_x > $max_x) {
            $max_x = $new_x;
        }
        if ($new_y > $max_y) {
            $max_y = $new_y;
        }
    }
}

say "X: [$min_x, $max_x]";
say "Y: [$min_y, $max_y]";

my $out_img = Imager->new(xsize => $width,
                          ysize => $height);

foreach my $y (0 .. $height - 1) {
    foreach my $x (0 .. $width - 1) {
        my ($new_x, $new_y) = @{$matrix[$y][$x]};
        $new_x = map_val($new_x, $min_x, $max_x, 0, $width - 1);
        $new_y = map_val($new_y, $min_y, $max_y, 0, $height - 1);
        $out_img->setpixel(
                           x     => $new_x,
                           y     => $new_y,
                           color => $img->getpixel(x => $x, y => $y),
                          );
    }
}

$out_img->write(file => 'julia_transform.png');
