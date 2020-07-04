#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 19 December 2016
# https://github.com/trizen

# Draws a square with diagonals made out of circles.

use 5.010;
use strict;
use warnings;

use GD::Simple;

my $img = 'GD::Simple'->new(1000, 1000);
$img->fgcolor('blue');
$img->bgcolor(undef);
$img->moveTo(200, 150);

my $n    = 15;
my $size = 45;

my $dsize = $size / (1 + sqrt(2));
my $dmove = $size / 4;

for (1 .. $n) {
    my ($x, $y) = $img->curPos;
    $img->moveTo($x, $y + $size);
    $img->ellipse($size, $size);
}

for (1 .. $n - 1) {
    my ($x, $y) = $img->curPos;
    $img->moveTo($x + $size, $y);
    $img->ellipse($size, $size);
}

for (1 .. $n - 1) {
    my ($x, $y) = $img->curPos;
    $img->moveTo($x, $y - $size);
    $img->ellipse($size, $size);
}

my ($x, $y) = $img->curPos;

for (1 .. $n - 1) {
    my ($x, $y) = $img->curPos;
    $img->moveTo($x - $size, $y);
    $img->ellipse($size, $size);
}

for (1 .. 4 * ($n - 1) - 2) {
    my ($x, $y) = $img->curPos;
    $img->moveTo($x + $dmove, $y + $dmove);
    $img->ellipse($dsize, $dsize) if $_ > 1;
}

$img->moveTo($x, $y);

for (1 .. 4 * ($n - 1) - 2) {
    my ($x, $y) = $img->curPos;
    $img->moveTo($x - $dmove, $y + $dmove);
    $img->ellipse($dsize, $dsize) if $_ > 1;
}

open my $fh, '>:raw', 'square_of_circles.png';
print $fh $img->png;
close $fh;
