#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 14 September 2016
# Website: https://github.com/trizen

# For each factor `f` of a composite number `n`, draw a circle
# in such a way that the line of the circle passes through both `n` and `f`.

use 5.014;
use strict;
use warnings;

use Imager;
use List::Util qw(uniq);
use ntheory qw(is_prime factor);

my $limit = 1000;
my $scale = 10;
my $red   = Imager::Color->new('#ff0000');

my $img = Imager->new(xsize => $limit * $scale,
                      ysize => $limit * $scale,);

sub get_circle {
    my ($n, $f) = @_;
    my $r = ($n * $scale - $f * $scale) / 2;
    ($r, $r + $f * $scale, $limit * $scale / 2);
}

foreach my $n (1 .. $limit) {
    if (not is_prime($n)) {
        foreach my $f (uniq(factor($n))) {
            my ($r, $x, $y) = get_circle($n, $f);
            $img->circle(
                         x      => $x,
                         y      => $y,
                         r      => $r,
                         color  => $red,
                         filled => 0
                        );
        }
    }
}

$img = $img->rotate(degrees => 90);
$img->write(file => 'factor_circles.png');
