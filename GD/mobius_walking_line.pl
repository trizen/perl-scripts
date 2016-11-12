#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13 November 2016
# Website: http://github.com/trizen

# Draw a line using the values of the Möbius function: μ(n)

# The rules are the following:
#   when μ(n) = -1, the angle is changed to -45 degrees
#   when μ(n) = +1, the angle is changed to +45 degrees
#   when μ(n) =  0, the angle is changed to   0 degrees

# In all three cases, a pixel is recorded for each value of μ(n).

use 5.010;
use strict;
use warnings;

use GD::Simple;
use ntheory qw(moebius);

my $width  = 1000;
my $height = 100;

my $img = GD::Simple->new($width, $height);

$img->moveTo(0, $height / 2);

foreach my $u (moebius(1, $width)) {
    if ($u == 1) {
        $img->angle(45);
    }
    elsif ($u == -1) {
        $img->angle(-45);
    }
    else {
        $img->angle(0);
    }
    $img->line(1);
}

open my $fh, '>:raw', 'output.png';
print $fh $img->png;
close $fh;
