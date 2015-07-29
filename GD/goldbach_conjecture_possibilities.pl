#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 29 July 2015
# Website: https://github.com/trizen

# Plot the number of possibilities of each number for the Goldbach conjecture.

# Example:
# 16 = {3+13; 5+11}  => 2 possibilities for the number 16

use 5.010;
use strict;
use warnings;

use Imager qw();
use ntheory qw(forprimes is_prime);

my $limit = 1e4;

my $xsize = $limit;
my $ysize = (($limit / log($limit)) + sqrt($limit) + ($limit / 10**(int(log($limit) / log(10)) - 1))) / 2;    # an approximation

my ($x, $y) = (0, $ysize);
my $img = Imager->new(xsize => $xsize, ysize => $ysize);

my $white = Imager::Color->new('#FFFFFF');
my $gray  = Imager::Color->new('#5f5d5d');

$img->box(filled => 1, color => $white);

foreach my $i (2 .. $limit) {
    my $n     = 2 * $i;
    my $count = 0;

    my %seen;
    forprimes {
        $seen{$_} && return;
        if (is_prime($n - $_)) {
            ++$count;
            ++$seen{$n - $_};
        }
    }
    ($n - 2);

    if ($count == 0) {
        die "The goldbach conjecture has been proved false for n=$n\n";
    }

    foreach my $i (1 .. $count) {
        $img->setpixel(x => $x, y => $y - $i, color => $gray);
    }

    $x += 1;
}

$img->write(file => "goldbach.png");
