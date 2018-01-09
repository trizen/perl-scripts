#!/usr/bin/perl

# Draw Koch snowflakes as concentric rings, using Math::PlanePath.

# See also:
#   https://en.wikipedia.org/wiki/Koch_snowflake
#   https://metacpan.org/pod/Math::PlanePath::KochSnowflakes

use 5.010;
use strict;
use warnings;

use Math::PlanePath::KochSnowflakes;
my $path = Math::PlanePath::KochSnowflakes->new;

use Imager;

my $img = Imager->new(xsize => 1000, ysize => 1000);
my $red = Imager::Color->new('#ff0000');

foreach my $n (1 .. 100000) {
    my ($x, $y) = $path->n_to_xy($n);
    $img->setpixel(x => 500 + $x, y => 500 + $y, color => $red);
}

$img->write(file => 'Koch_snowflakes.png');
