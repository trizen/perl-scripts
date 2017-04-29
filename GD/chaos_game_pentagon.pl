#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 29 April 2017
# https://github.com/trizen

# Chaos game, generating a Sierpinski pentagon.

# See also:
#   https://www.youtube.com/watch?v=kbKtFN71Lfs
#   https://www.youtube.com/watch?v=e0JaZuLfZ_0 (starting from 18:03)

use 5.010;
use strict;
use warnings;

use Imager;

my $width  = 1000;
my $height = 1000;

my @points = (
    [$width/2,              0],
    [0,           $height/2.5],
    [$width,      $height/2.5],
    [$width/5,        $height],
    [$width-$width/5, $height],
);

my $img = Imager->new(
                      xsize    => $width,
                      ysize    => $height,
                      channels => 3,
                     );

my $color = Imager::Color->new('#ff0000');
my $r = [$points[rand(@points)], $points[rand(@points)]];

foreach my $i (1 .. 100000) {
    my $p = $points[rand @points];

    my $h = [
        sprintf('%.0f',($p->[0] + $r->[0]) / 3) + $width/6,
        sprintf('%.0f',($p->[1] + $r->[1]) / 3) + $height/5,
    ];

    $img->setpixel(
        x     => $h->[0],
        y     => $h->[1],
        color => $color,
    );

    $r = $h;
}

$img->write(file => 'chaos_game_pentagon.png');
