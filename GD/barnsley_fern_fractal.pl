#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 20 March 2016
# Website: https://github.com/trizen

# Perl implementation of the Barnsley fern fractal.
# See: https://en.wikipedia.org/wiki/Barnsley_fern

use Imager;

my $w = 640;
my $h = 640;

my $img = Imager->new(xsize => $w, ysize => $h, channels => 3);
my $green = Imager::Color->new('#00FF00');

my ($x, $y) = (0, 0);

foreach (1 .. 1e5) {
  my $r = rand(100);
  ($x, $y) =
    $r <=  1 ? ( 0.00 * $x - 0.00 * $y,  0.00 * $x + 0.16 * $y + 0.00) :
    $r <=  8 ? ( 0.20 * $x - 0.26 * $y,  0.23 * $x + 0.22 * $y + 1.60) :
    $r <= 15 ? (-0.15 * $x + 0.28 * $y,  0.26 * $x + 0.24 * $y + 0.44) :
               ( 0.85 * $x + 0.04 * $y, -0.04 * $x + 0.85 * $y + 1.60) ;
  $img->setpixel(x => $w / 2 + $x * 60, y => $y * 60, color => $green);
}

$img->flip(dir => 'v');
$img->write(file => 'barnsleyFern.png');
