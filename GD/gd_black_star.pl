#!/usr/bin/perl

use integer;
use GD::Simple;

$img = 'GD::Simple'->new(1000, 1000);
$img->moveTo(700, 500);

my $nr = 442;

sub t { $img->turn($_[0]) }
sub l { $img->line($_[0]) }

for (0 .. $nr) {
    t 45;

    #l $nr+$_;
    t -180;
    l $nr/ 2;
    t 45;
    l $nr / 2;
    t -180;
    l $nr;

    #t -180;
    #l $nr / 2;
    #t 90;
    #l $nr/2;
    t -180;
    l $nr+ $_;
}

my $image_name = 'turtle.png';

open my $fh, '>', $image_name or die $!;
print {$fh} $img->png;
close $fh;

system "gliv", $image_name;
