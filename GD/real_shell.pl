#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 30 April 2014
# Website: http://github.com/trizen

use 5.010;
use strict;
use warnings;
use GD::Simple;

my $img = 'GD::Simple'->new(500, 600);

sub t($) {
    $img->turn(shift);
}

sub l($) {
    $img->line(shift);
}

sub c($) {
    $img->fgcolor(shift);
}

{
    $img->clear;
    $img->moveTo(250, 300);    # hopefully, at the center of the image

    my $loop = 5;
    for (my $j = 0.01 ; $j <= $loop ; $j += 0.01) {
        l $j;
        t $loop- $j + 1;
    }

    my $image_name = "turtle.png";

    open my $fh, '>', $image_name or die $!;
    print {$fh} $img->png;
    close $fh;

    ## View the image as soon as it is generated
    system "gliv", $image_name;    # edit this line
    $? == 0 or die "Non-zero exit code of the image viewer: $?";
}
