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

sub t($) {
    $img->turn(shift);
}

sub l($) {
    $img->line(shift);
}

sub c($) {
    $img->fgcolor(shift);
}

for (my $loop = 45 ; $loop <= 180 ; $loop += 1) {

    say "$loop degrees";

    $img->clear;
    $img->moveTo(500, 300);    # hopefully, at the center of the image

    for my $j (1 .. 360) {
        l $j;
        t $loop;
    }

    my $image_name = "turtle.png";

    open my $fh, '>', $image_name or die $!;
    print {$fh} $img->png;
    close $fh;

    ## View the image as soon as it is generated
    system "gliv", $image_name;    # edit this line
    $? == 0 or die "Non-zero exit code of the image viewer: $?";
}
