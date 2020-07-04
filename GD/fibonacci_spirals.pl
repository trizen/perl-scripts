#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 18 July 2015
# https://github.com/trizen

#
## Generate a Fibonacci cluster of spirals.
#

use 5.010;
use strict;
use warnings;
use GD::Simple;

my $img = 'GD::Simple'->new(8000, 8000);
$img->moveTo(3500, 3500);

sub t($) {
    $img->turn(shift);
}

sub l($) {
    $img->line(shift);
}

sub c($) {
    $img->fgcolor(shift);
}

sub fibonacci(&$) {
    my ($callback, $n) = @_;
    my @fib = (1, 1);
    for (1 .. $n - 2) {
        $callback->($fib[0]);
        @fib = ($fib[-1], $fib[-1] + $fib[-2]);
    }
    $callback->($_) for @fib;
}

c 'red';
for my $i (1 .. 180) {
    fibonacci {
        l $_[0]**(1 / 11);
        t $i;
    }
    $i;
    t 0;
}

my $image_name = 'fibonacci_spirals.png';

open my $fh, '>:raw', $image_name or die $!;
print {$fh} $img->png;
close $fh;
