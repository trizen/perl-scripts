#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 18 July 2015
# https://github.com/trizen

#
## Generate an interesting cluster of shapes based on the Stern-Brocot sequence.
#

use 5.010;
use strict;
use warnings;
use GD::Simple;

my $img = 'GD::Simple'->new(5000, 5000);
$img->moveTo(2100, 2500);

sub t($) {
    $img->turn(shift);
}

sub l($) {
    $img->line(shift);
}

sub c($) {
    $img->fgcolor(shift);
}

sub stern_brocot(&$) {
    my ($callback, $n) = @_;

    my @fib = (1, 1);
    foreach my $i (1 .. $n) {
        push @fib, $fib[0] + $fib[1], $fib[1];
        $callback->($fib[0]);
        shift @fib;
    }
    $callback->($_) for @fib;
}

c 'red';
for my $i (1 .. 180) {
    stern_brocot {
        l $i/ $_[0];
        t $i;
    }
    $i;
    t 0;
}

my $image_name = 'stern_brocot_shapes.png';

open my $fh, '>:raw', $image_name or die $!;
print {$fh} $img->png;
close $fh;
