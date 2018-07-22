#!/usr/bin/perl

use strict;
use warnings;

use GD::Simple;

my $img = 'GD::Simple'->new(1000, 1000);
$img->moveTo(285, 80);

my $nr = 257;

for (0 .. 100) {
    $img->fgcolor('green');
    $img->turn($nr);
    $img->line(-$nr);
    $img->line(-$nr);
    $img->line(-$nr);
    $img->line(-$nr);
    $img->fgcolor('gray');
    $img->turn(-$nr);
    $img->line($nr);
    $img->line($nr);
    $img->line($nr);
    $img->line($nr);
    $img->fgcolor('blue');
    $img->turn(-$nr);
    $img->line($nr);
    $img->fgcolor('purple');
    $img->turn($nr);
    $img->line(-$nr);
    $img->fgcolor('red');
    $img->turn($nr);
    $img->line(-$nr);
}

my $image_name = 'trizen_old_logo.png';

open my $fh, '>', $image_name or die $!;
print {$fh} $img->png;
close $fh;
