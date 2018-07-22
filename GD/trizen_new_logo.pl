#!/usr/bin/perl

use strict;
use warnings;

use GD::Simple;

my $img = 'GD::Simple'->new(2000, 2000);
$img->moveTo(510, 1100);

my $nr = 308.5;

for (0 .. 280) {

    $img->fgcolor('green');
    $img->turn($nr);

    for (1 .. 4) {
        $img->line(-$nr);
    }

    $img->fgcolor('gray');
    $img->turn(-$nr);

    for (1 .. 4) {
        $img->line($nr);
    }

    $img->fgcolor('blue');
    $img->line($nr);

    $img->fgcolor('purple');
    $img->turn($nr);
    $img->line(-$nr);

    $img->fgcolor('red');
    $img->line(-$nr);
}

my $image_name = 'trizen_new_logo.png';

open my $fh, '>:raw', $image_name or die $!;
print {$fh} $img->png;
close $fh;
