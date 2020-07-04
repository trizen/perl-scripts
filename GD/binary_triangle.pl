#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 16 January 2017
# https://github.com/trizen

# Draws a balanced binary triangle with n branches on each side.

use 5.010;
use strict;
use warnings;

use Imager;
use ntheory qw(:all);

sub line {
    my ($img, $x, $y, $d, $n) = @_;

    my $x2 = $x + $n * $d;
    my $y2 = $y + $n * ($d ? 1 : 0);

    $img->line(
               color => 'red',
               x1    => $x,
               x2    => $x2,
               y1    => $y,
               y2    => $y2,
              );

    return if $n <= 1;

    line($img, $x2, $y2, +1, $n >> 1);
    line($img, $x2, $y2, -1, $n >> 1);
}

my $n = 1024;

my $img = Imager->new(xsize => $n * 2, ysize => $n);
line($img, $n, 0, 0, $n);
$img->write(file => 'binary_triangle.png');
