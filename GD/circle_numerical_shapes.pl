#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 27 November 2016
# https://github.com/trizen

# Generates circle-like shapes for arbitrary numerical values (based on Euler's identity).

use 5.010;
use strict;
use warnings;

use GD::Simple;
use Math::Complex;

my ($width, $height) = (1000, 1000);
my $img = 'GD::Simple'->new($width, $height);

my $center = ($width + $height) / 4;
$img->moveTo($center, $center);

my $number      = 9;       # draw a representation for this number
my $granularity = 3000;    # the amount of granularity / detail

my $step1 = $number / $granularity;
my $step2 = $step1 / $number;

my $pi = atan2(0, -'inf');
my $tau = 2 * $pi;

my $scale = 300;
my $color = $img->colorAllocate(255, 0, 0);

for (my ($i, $j) = (0, 0) ; $j <= $tau ; $i += $step1, $j += $step2) {
    my $point1 = exp($pi * i * $i);
    my $point2 = exp($pi * i * $j);

    my $re1 = $center + $point1->Re * $scale;
    my $im1 = $center + $point1->Im * $scale;

    my $re2 = $center + $point2->Re * $scale;
    my $im2 = $center + $point2->Im * $scale;

    $img->setPixel(($re1 + $re2) / 2, ($im1 + $im2) / 2, $color);
}

my $image_name = "circle_$number.png";

open my $fh, '>:raw', $image_name or die "error: $!";
print {$fh} $img->png;
close $fh;
