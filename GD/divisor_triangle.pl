#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 14 September 2016
# Website: https://github.com/trizen

# Generates a triangle with non-prime and non-power numbers,
# each number connected through a line to its divisors.

use strict;
use warnings;

use Imager;
use ntheory qw(is_prime is_power divisors);

use POSIX qw(ceil);
use Memoize qw(memoize);

memoize('get_point');

my $limit = 10;
my $scale = 1000;
my $red   = Imager::Color->new('#ff0000');

my $img = Imager->new(xsize => 2 * $limit * $scale,
                      ysize => $limit * $scale);

sub get_point {
    my ($n) = @_;

    my $row  = ceil(sqrt($n));
    my $cell = 2 * $row - 1 - $row**2 + $n;

    ($scale * $cell, $scale * $row);
}

foreach my $n (1 .. $scale) {
    if (not is_prime($n) and not is_power($n)) {

        my ($x1, $y1) = get_point($n);

        foreach my $divisor (divisors($n)) {
            my ($x2, $y2) = get_point($divisor);
            $img->line(
                       x1    => ($limit * $scale - $y1 - 1) + $x1,
                       y1    => $y1,
                       x2    => ($limit * $scale - $y2 - 1) + $x2,
                       y2    => $y2,
                       color => $red
                      );
        }
    }
}

$img->write(file => 'divisor_triangle.png');
