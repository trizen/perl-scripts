#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 16 July 2014
# Website: http://github.com/trizen

use strict;
use warnings;
use GD::Simple;

my $img;

sub t($) {
    $img->turn(shift);
}

sub l($) {
    $img->line(shift);
}

sub c($) {
    $img->fgcolor(shift);
}

my $dir = 'Regular poligons';

if (not -d $dir) {
    mkdir($dir) || die "Can't mkdir `$dir': $!";
}

chdir($dir) || die "Can't chdir `$dir': $!";

foreach my $i (1 .. 144) {
    if (360 % (180 - $i) == 0) {

        my $sides = 360 / (180 - $i);
        printf("Angle: %d\tSides: %d\n", $i, $sides);

        $img = 'GD::Simple'->new(1000, 1000);
        $img->moveTo(500, 500);

        for (1 .. $sides) {
            l 150;
            t 180 - $i;
        }

        my $image_name = sprintf("%03d.png", $i);
        open my $fh, '>:raw', $image_name or die $!;
        print {$fh} $img->png;
        close $fh;
    }
}
