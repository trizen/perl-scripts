#!/usr/bin/perl

use strict;
use warnings;

use GD::Simple;

my $img = 'GD::Simple'->new(2500, 2500);
$img->moveTo(1220, 1220);

my $nr = 360.01;

for (0 .. 150) {
    $img->turn(-$nr);
    $img->line($nr);
    $img->turn(180);
    $img->line(-$nr);
    $img->line($nr);
    $img->turn(45);
    $img->line(-$nr);
    $img->turn(180);
    $img->line($nr);
    $img->line(-$nr);
    $img->turn(45);
    $img->line($nr);
    $img->turn(180);
    $img->line(-$nr);
    $img->line($nr);
    $img->turn(45);
    $img->line(-$nr);
    $img->turn(180);
    $img->line($nr);
    $img->line(-$nr);
    $img->turn(45);
    $img->line($nr);
    $img->turn(180);
    $img->line(-$nr);
    $img->line($nr);
    $img->turn(45);
    $img->line(-$nr);
    $img->turn(180);
    $img->line($nr);
    $img->line(-$nr);
    $img->turn(45);
    $img->line($nr);
    $img->turn(180);
    $img->line(-$nr);
    $img->line($nr);
    $img->turn(45);
    $img->line(-$nr);
    $img->turn(180);
    $img->line($nr);
    $img->line(-$nr);
}

my $image_name = 'star_turtle.png';

open my $fh, '>:raw', $image_name or die $!;
print {$fh} $img->png;
close $fh;
