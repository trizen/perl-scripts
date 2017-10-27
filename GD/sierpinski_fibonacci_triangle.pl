#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 12 October 2017
# https://github.com/trizen

# Generation of the Sierpinski triangle form a lagged Fibonacci sequence mod 2.

# See also:
#   https://projecteuler.net/problem=258
#   https://en.wikipedia.org/wiki/Sierpinski_triangle

use 5.020;
use strict;
use warnings;

use Imager;
use experimental qw(signatures);

my $size = 1000;
my $red  = Imager::Color->new('#ff0000');

my $img = Imager->new(xsize => $size,
                      ysize => $size);

sub fibmod_seq ($n, $lag, $mod) {

    my @g = (1) x $lag;

    foreach my $k ($lag .. $n) {

        my $x = $g[$k - $lag];
        my $y = $g[$k - $lag - 1];

        $g[$k] = ($x + $y) % $mod;
    }

    return @g;
}

my $n   = $size**2;
my $lag = $size;
my $mod = 2;

my @g = fibmod_seq($n, $lag, $mod);

foreach my $i (0 .. $#g) {

    if ($g[$i]) {
        $img->setpixel(
                       x     => $i % $lag,
                       y     => int($i / $lag),
                       color => $red,
                      );
    }
}

$img->write(file => 'sierpinski_fibonacci_triangle.png');
