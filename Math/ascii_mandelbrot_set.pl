#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 03 January 2018
# https://github.com/trizen

# ASCII generation of the Mandelbrot set (+ANSI colors).

# See also:
#   https://en.wikipedia.org/wiki/Mandelbrot_set

use 5.010;
use strict;
use warnings;

use Math::GComplex;
use Term::ANSIColor qw(:constants);

my @colors = (
              (BLACK), (RED),   (GREEN),        (YELLOW),     (BLUE),         (MAGENTA),
              (CYAN),  (WHITE), (BRIGHT_BLACK), (BRIGHT_RED), (BRIGHT_GREEN), (BRIGHT_YELLOW),
              (BRIGHT_BLUE), (BRIGHT_MAGENTA), (BRIGHT_CYAN), (BRIGHT_WHITE),
             );

my @chars = (' ', '`', '.', ',', ':', ';', '!', '*', '%', '#');

sub range_map {
    my ($value, $in_min, $in_max, $out_min, $out_max) = @_;
    ($value - $in_min) * ($out_max - $out_min) / ($in_max - $in_min) + $out_min;
}

sub mandelbrot {
    my ($z) = @_;

    state $I = 30;
    state $L = 100;

    my $n = 0;
    my $c = $z;

    while (abs($z) < $L and ++$n <= $I) {
        $z = $z * $z + $c;
    }

    return ($I - $n) / $I;
}

for (my $y = 1 ; $y >= -1 ; $y -= 0.05) {
    for (my $x = -2 ; $x <= 0.5 ; $x += 0.0315) {
        my $num = mandelbrot(Math::GComplex->new($x, $y));
        my $color_index = sprintf('%.0f', range_map($num, 0, 1, 0, $#colors));
        my $char_index  = sprintf('%.0f', range_map($num, 0, 1, 0, $#chars));
        print($colors[$color_index] . $chars[$char_index]);
    }
    print "\n";
}

print (RESET);
