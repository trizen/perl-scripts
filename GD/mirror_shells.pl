#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 30 April 2014
# Website: http://github.com/trizen

use 5.010;
use strict;
use warnings;
use GD::Simple;

my $img = 'GD::Simple'->new(1000, 600);
$img->moveTo(220, 240);    # hopefully, at the center of the image

sub t($) {
    $img->turn(shift);
}

sub l($) {
    $img->line(shift);
}

sub c($) {
    $img->fgcolor(shift);
}

my $loop = 50;
t 260;

# From inside-out
for my $j (1 .. $loop) {
    l $j;
    t $loop- $j + 1;
}

t 180;

# From outside-in
for my $j (1 .. $loop) {
    l $loop- $j + 1;
    t $j;
}

my $image_name = "turtle.png";

open my $fh, '>', $image_name or die $!;
print {$fh} $img->png;
close $fh;

## View the image as soon as it is generated
system "gliv", $image_name;    # edit this line
$? == 0 or die "Non-zero exit code of the image viewer: $?";
