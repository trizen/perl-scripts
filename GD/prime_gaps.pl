#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 29 July 2015
# Website: https://github.com/trizen

# Plot the differences between any two consecutive primes.

# Example:
#   29 - 23 = 6
#   43 - 41 = 2

use 5.010;
use strict;
use warnings;

use Imager qw();
use ntheory qw(next_prime nth_prime);

my $limit = 1e4;
my $max   = -'inf';

my $last_prime = nth_prime($limit**3 * 3);    # start with this prime

my $xsize = $limit;
my $ysize = int(log($last_prime) * 10);       # approximation for the maximum difference

my ($x, $y) = (0, $ysize);
my $img = Imager->new(xsize => $xsize, ysize => $ysize);

my $white = Imager::Color->new('#FFFFFF');
my $gray  = Imager::Color->new('#5f5d5d');

$img->box(filled => 1, color => $white);

foreach my $i (1 .. $limit) {
    my $prime = next_prime($last_prime);
    my $diff  = $prime - $last_prime;

    $max = $diff if $diff > $max;

    foreach my $i (1 .. $diff) {
        $img->setpixel(x => $x, y => $y - $i, color => $gray);
    }

    $last_prime = $prime;
    $x += 1;
}

say "Maximum difference: $max";
say "Predicted difference: $ysize";

$img->write(file => "prime_gaps.png");
