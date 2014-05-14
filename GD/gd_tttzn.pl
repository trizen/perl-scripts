#!/usr/bin/perl

use GD::Simple;

$img = 'GD::Simple'->new(2300, 2300);
$img->moveTo(465, 1305);

my $nr = 308.5;

for (0 .. 222) {
    $img->fgcolor(qw(blue green) [$_ % 2]);
    $img->turn(45);
    $img->line(-$nr - $_);
    $img->line(-$nr);
    $img->line(-$nr);
    $img->line(-$nr);
    $img->fgcolor(qw(green blue) [$_ % 2]);
    $img->turn(-45);
    $img->line($nr);
    $img->line($nr);
    $img->line($nr);
    $img->line($nr);
    $img->fgcolor('black');
    $img->turn(45);
    $img->line($nr + $_);
    $img->fgcolor('purple');
    $img->turn(-45);
    $img->line(-$nr);
    $img->line(-$nr);
}

my $image_name = 'turtle.png';

open my $fh, '>:raw', $image_name or die $!;
print {$fh} $img->png;
close $fh;

system "gliv", $image_name;
