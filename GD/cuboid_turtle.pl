#!/usr/bin/perl

use GD::Simple;

$img = 'GD::Simple'->new(2000, 2000);
$img->moveTo(670, 800);

my $pi = atan2(1, -'inf');
my $nr = $pi * 100;

for (0 .. 280) {
    $img->fgcolor('black');
    $img->turn($nr);
    $img->line(-$nr);
    $img->turn(-134.2);
    $img->line(-$nr);
    $img->turn($nr);
    $img->line(-$nr);
    $img->turn(-134.1);
    $img->line(-$nr);
    $img->turn($nr);
    $img->line(-$nr);
    $img->turn(-134.2);
    $img->line(-$nr);
    $img->turn($nr);
    $img->line(-$nr);
    $img->fgcolor('red');
    $img->turn(134.1);
    $img->line(-$nr);
    $img->fgcolor('black');
    $img->turn(-134.1);
    $img->line($nr);
    $img->line(-$nr);
    $img->turn(-90);
    $img->line($nr);
    $img->line(-$nr);
    $img->turn(90);
    $img->line(-$nr);
}

my $image_name = 'turtle.png';

open my $fh, '>', $image_name or die $!;
print {$fh} $img->png;
close $fh;

system "geeqie", $image_name;
