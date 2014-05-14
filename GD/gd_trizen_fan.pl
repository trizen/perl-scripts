#!/usr/bin/perl

use strict;
use GD::Simple;

my $img = 'GD::Simple'->new(2503, 2500);
$img->moveTo(540, 1980);

my $nr = 360;

for (0 .. 20) {

    # T
    $img->fgcolor('purple');
    $img->turn(-90);
    $img->line(--$nr / 10);
    $img->turn(90);
    $img->line($nr);
    $img->turn(90);
    $img->line($nr / 10);
    $img->turn(90);
    $img->move($nr / 2);
    $img->turn(90);
    $img->move($nr / 10);
    $img->turn(-180);
    $img->line($nr);
    $img->turn(-90);

    # R
    $img->fgcolor('green');
    $img->move($nr / 1.5);
    $img->turn(-90);
    $img->line($nr);
    $img->turn(90);
    $img->line($nr / 2 - ($nr / 10));
    $img->turn(45);
    $img->line($nr / 10);
    $img->turn(90 - 45);
    $img->line($nr / 2 - ($nr / 10));
    $img->turn(45);
    $img->line($nr / 10);
    $img->turn(90 - 45);
    $img->line($nr / 2 - ($nr / 10));
    $img->turn(-180 + 45);
    $img->line($nr / 2 + ($nr / 4) - ($nr / 10));
    $img->turn(-180 + 45);
    $img->line($nr / 10);
    $img->turn(180);
    $img->move($nr / 10);

    $nr -= ($_);

    # I
    $img->fgcolor('black');    # blue
    $img->turn(-90);
    $img->move($nr / 4);
    $img->turn(-90);
    $img->line($nr);
    $img->move($nr / 10);
    $img->turn(180);
    $img->move($nr / 10 + 12 + (12 / 2));
    $img->turn(-90);
    $img->move($nr / 5);

    # star
    $img->line(12);
    $img->turn(180);
    $img->line(-12);
    $img->line(12);
    $img->turn(45);
    $img->line(-12);
    $img->turn(180);
    $img->line(12);
    $img->line(-12);
    $img->turn(45);
    $img->line(12);
    $img->turn(180);
    $img->line(-12);
    $img->line(12);
    $img->turn(45);
    $img->line(-12);
    $img->turn(180);
    $img->line(12);
    $img->line(-12);
    $img->turn(45);
    $img->line(12);
    $img->turn(180);
    $img->line(-12);
    $img->line(12);
    $img->turn(45);
    $img->line(-12);
    $img->turn(180);
    $img->line(12);
    $img->line(-12);
    $img->turn(45);
    $img->line(12);
    $img->turn(180);
    $img->line(-12);
    $img->line(12);
    $img->turn(45);
    $img->line(-12);
    $img->turn(180);
    $img->line(12);
    $img->line(-12);
    $nr += ($_);

    # Z
    $img->fgcolor('red');
    $img->turn(-45);
    $img->move($nr + (12 * 6));
    $img->turn(-90);
    $img->move($nr / 7);
    $img->turn(-65);
    $img->line($nr + ($nr / 10));
    $img->turn(-180 + 65);
    $img->line($nr / 2);
    $img->turn(-90);
    $img->line($nr / 10);
    $img->turn(180);
    $img->move($nr / 10);
    $img->turn(90 + 65);
    $img->move($nr + ($nr / 10));
    $img->turn(-90 - 65);
    $img->line($nr / 10);
    $img->turn(180);
    $img->move($nr / 10);
    $img->turn(90);
    $img->line($nr / 2 - ($nr / 7) / 2);
    $img->turn(180 - 65);
    $img->move(($nr + ($nr / 10)) / 2);
    $img->turn(-180 + 65);
    $img->line($nr / 4);
    $img->turn(-90);
    $img->line($nr / 10);
    $img->turn(180);
    $img->move($nr / 10);
    $img->turn(90);
    $img->line($nr / 2);
    $img->turn(-90);
    $img->line($nr / 10);

    # E
    $img->fgcolor('orange');
    $img->turn(180);
    $img->move($nr / 2 + ($nr / 10));
    $img->turn(-90);
    $img->move($nr / 5);
    $img->turn(-90);
    $img->line($nr);
    $img->turn(90);
    $img->line($nr / 2);
    $img->turn(90);
    $img->move($nr / 2);
    $img->turn(90);
    $img->line($nr / 2);
    $img->turn(-90);
    $img->move($nr / 2);
    $img->line($nr / 2);

    # N
    $img->fgcolor('blue');
    $img->turn(0);
    $img->move($nr / 4);
    $img->turn(-90);
    $img->line($nr);
    $img->turn(90 + 65);
    $img->line($nr + ($nr / 10));
    $img->turn(-90 - 65);
    $img->line($nr);
}

$nr = 308.5 - (308.5 / 8);
$img->moveTo(830, 1380);

for (0 .. 623) {
    $img->fgcolor('green');
    $img->turn($nr);
    $img->line(-$nr);
    $img->line(-$nr);
    $img->line(-$nr);
    $img->line(-$nr);
    $img->fgcolor('black');
    $img->turn(-$nr);
    $img->line($nr);
    $img->line($nr);
    $img->line($nr);
    $img->line($nr);
    $img->turn(-$nr);
    $img->line($nr);
    $img->fgcolor('red');
    $img->turn($nr);
    $img->line(-$nr);
    $img->fgcolor('red');
    $img->line(-$nr);
}

my $image_name = 'turtle.png';

open my $fh, '>', $image_name or die $!;
print {$fh} $img->png;
close $fh;

system "geeqie", $image_name;
