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
use ntheory qw(primes is_prime);

my $limit = 1e4;

my $xsize = $limit;
my $ysize = int($limit / (1 / 5 * log($limit)**2));    # approximation

my ($x, $y) = (0, $ysize);
my $img = Imager->new(xsize => $xsize, ysize => $ysize);

my $white = Imager::Color->new('#ffffff');
my $gray  = Imager::Color->new('#5f5d5d');

$img->box(filled => 1, color => $white);

my @primes;
my $last_n = 2;
foreach my $i (3 .. $limit) {

    my $n = 2 * $i;
    push @primes, @{primes($last_n, $n - 2)};
    $last_n = $n - 2;

    my %seen;
    my $count = 0;
    foreach my $prime (@primes) {
        exists($seen{$prime}) && last;
        if (is_prime($n - $prime)) {
            ++$count;
            undef $seen{$n - $prime};
        }
    }

    foreach my $i (1 .. $count) {
        $img->setpixel(x => $x, y => $y - $i, color => $gray);
    }

    $x += 1;
}

$img->write(file => "goldbach_possibilities.png");
