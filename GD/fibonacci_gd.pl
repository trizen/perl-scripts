#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 18 May 2014
# https://github.com/trizen

use 5.010;
use strict;
use warnings;
use GD::Simple;

my $img = 'GD::Simple'->new(1500, 1000);
$img->moveTo(250, 530);

sub t($) {
    $img->turn(shift);
}

sub l($) {
    $img->line(shift);
}

sub c($) {
    $img->fgcolor(shift);
}

sub fib {
    my ($n) = @_;
    my $res = $n < 2 ? $n : fib($n - 2) + fib($n - 1);
    l($res * 4);
    t(90);
    $res;
}

fib(14);

my $image_name = 'fibonacci_turtle.png';

open my $fh, '>', $image_name or die $!;
print {$fh} $img->png;
close $fh;
