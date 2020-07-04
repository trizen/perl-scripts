#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 29 April 2014
# https://github.com/trizen

# A funny fanny shape. :-)

use strict;
use warnings;
use GD::Simple;

my $img = 'GD::Simple'->new(1000, 1000);
$img->moveTo(500, 500);

sub t($) {
    $img->turn(shift);
}

sub l($) {
    $img->line(shift);
}

sub c($) {
    $img->fgcolor(shift);
}

for my $i (1 .. 180) {
    c 'red';
    for (1 .. 360) {
        l 4;    # size
        t 1;
    }
    t 0;
}

my $image_name = 'mathematical_butt.png';

open my $fh, '>:raw', $image_name or die $!;
print {$fh} $img->png;
close $fh;
