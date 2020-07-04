#!/usr/bin/perl

use strict;
use warnings;

use GD::Simple;

my $img = 'GD::Simple'->new(3000, 3000);
$img->moveTo(1660, 1780);

my $nr = 314.9;

for (0 .. 44) {
    $img->fgcolor('black');
    $img->turn($nr);
    $img->line(-$nr);
    $img->turn(-$nr);
    $img->line(-$nr);
    $img->turn($nr);
    $img->line($nr);
    $img->fgcolor('gray');
    $img->turn(-$nr);
    $img->line($nr);
    $img->line($nr);
    $img->turn($nr);
    $img->line(-$nr);
    $img->turn($nr);
    $img->line(-$nr);
    $img->fgcolor('red');
    $img->turn(-$nr);
    $img->line($nr);
    $img->line(-$nr);
    $img->turn($nr);
    $img->line(-$nr);
    $img->fgcolor('blue');
    $img->turn(-$nr);
    $img->line($nr);
    $img->turn($nr);
    $img->line($nr);
    $img->line($nr);
    $img->fgcolor('purple');
    $img->turn(-$nr);
    $img->line(-$nr);
    $img->line(-$nr);
}

my $image_name = 'cuboid_turtle_2.png';

open my $fh, '>', $image_name or die $!;
print {$fh} $img->png;
close $fh;
