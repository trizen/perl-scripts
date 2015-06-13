#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 30 April 2014
# Website: http://github.com/trizen

use 5.010;
use strict;
use warnings;
use GD::Simple;

my $img = 'GD::Simple'->new(2000, 2000);
$img->fgcolor('blue');

sub t($) {
    $img->turn(shift);
}

sub l($) {
    $img->line(shift);
}

sub c($) {
    $img->fgcolor(shift);
}

my $dir = 'Spinning Shapes';

if (not -d $dir) {
    mkdir($dir) || die "Can't mkdir `$dir': $!";
}

chdir($dir) || die "Can't chdir `$dir': $!";

for (my $i = 1 ; $i <= 180 ; $i += 1) {

    say "$i degrees";

    $img->clear;
    $img->moveTo(1000, 1000);    # hopefully, at the center of the image

    for my $j (1 .. 360) {
        l($j * 2);
        t $i;
    }

    my $image_name = sprintf("%03d.png", $i);

    open my $fh, '>:raw', $image_name or die $!;
    print {$fh} $img->png;
    close $fh;
}
