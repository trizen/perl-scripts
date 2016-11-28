#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 27 November 2016
# https://github.com/trizen

# Generates circle-like shapes for arbitrary numerical values (based on Euler's formula).

use 5.010;
use strict;
use warnings;

use GD::Simple;

my ($width, $height) = (1000, 1000);
my $img = 'GD::Simple'->new($width, $height);

my $center = ($width + $height) >> 2;
$img->moveTo($width >> 1, $height >> 1);

my $number      = 9;       # draw a representation for this number
my $granularity = 3000;    # the amount of granularity / detail

my $step1 = $number / $granularity;
my $step2 = $step1 / $number;

my $tau = 2 * atan2(0, -'inf');

my $scale = 300;
my $color = $img->colorAllocate(255, 0, 0);

for (my ($i, $j) = (0, 0) ; $j <= $tau ; $i += $step1, $j += $step2) {

    my ($x1, $y1, $x2, $y2) = (
        map { $_ * $scale + $center }
            (cos($i), sin($i), cos($j), sin($j))
    );

    $img->setPixel(($x1 + $x2) >> 1, ($y1 + $y2) >> 1, $color);
}

my $image_name = "circle_$number.png";

open my $fh, '>:raw', $image_name or die "error: $!";
print {$fh} $img->png;
close $fh;
