#!/usr/bin/perl

use GD::Simple;

$img = 'GD::Simple'->new(2500, 2500);
$img->moveTo(1370, 1580);

my $nr = 124;

sub t { $img->turn($_[0]) }
sub l { $img->line($_[0]) }

for (0 .. 125) {
    l $nr;
    t 90;
    l -$nr;
    l $nr;
    t -90;
    l $nr;
    l $nr/ 2;
    t 90;
    l $nr/ 2;
    t 90;
    l $nr;
    t -90;
    l $nr* 2;
    t -90;
    l $nr* 2;
    t -90;
    l $nr* 2;
    t -90;
    l $nr;
    t -180;
    l $nr;
    t 45;
    l $nr;
    t -180;
    l $nr;
    t -45;
    l $nr* 2;
    t -45;
    l $nr;
    t 90;
    l -$nr;
    t -45;
    l -$nr * 2;
    t -45;
    l -$nr;

    #last;
}

my $image_name = 'turtle.png';

open my $fh, '>', $image_name or die $!;
print {$fh} $img->png;
close $fh;

system "gliv", $image_name;
