#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 30 April 2014
# Website: http://github.com/trizen

# Generate mathematical shapes
# -- feel free to play with the numbers --

use 5.010;
use strict;
use warnings;
use GD::Simple;

my $img = 'GD::Simple'->new(3000, 3000);

sub t($) {
    $img->turn(shift);
}

sub l($) {
    $img->line(shift);
}

sub c($) {
    $img->fgcolor(shift);
}

my $dirname = "Dancing shapes";
-d $dirname or do {
    mkdir($dirname)
      or die "Can't mkdir '$dirname': $!";
};

chdir($dirname)
  or die "Can't chdir into '$dirname': $!";

foreach my $t (1 .. 179) {    # turn from 1 to 179
    for my $k (5 .. 9) {      # draw this many pictures for each turn

        # Info to STDOUT
        say "$t:$k";

        $img->clear;
        $img->moveTo(1500, 1500);    # hopefully, at the center of the image

        for my $i (1 .. $t) {        # another interesting set is from 1..$k
            for my $j (1 .. $k) {
                $img->fgcolor('green');
                l(40 * $j);          # the length of a given line (in pixels)
                $img->fgcolor('blue');
                l(-40 * ($j / 2));    # if you happen to love textiles, comment this line :)
                t $t;
            }
            $img->fgcolor('red');
            l 40;
            ##last;              # to generate only the basic shapes, uncomment this line.
        }

        my $image_name = sprintf('%03d-%02d.png', $t, $k);

        open my $fh, '>:raw', $image_name or die $!;
        print {$fh} $img->png;
        close $fh;

        ## View the image as soon as it is generated
        #system "gliv", $image_name;    # edit this line
        #$? == 0 or die "Non-zero exit code of the image viewer: $?";
    }
}
