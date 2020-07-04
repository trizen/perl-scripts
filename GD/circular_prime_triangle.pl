#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 02 April 2016
# http://github.com/trizen

# Generate a triangle with highlighted numbers in the form of: floor(sqrt(prime(i)^2 + i^2))

use 5.010;
use strict;
use warnings;

use Imager;
use List::Util qw(max);
use ntheory qw(nth_prime);

my %data;

sub generate {
    my ($n) = @_;

    foreach my $i (1 .. $n) {
        undef $data{int(sqrt(nth_prime($i)**2 + $i * $i))};
    }

    return 1;
}

generate(100000);

my $i = 1;
my $j = 1;

my $max   = max(keys %data);
my $limit = int(sqrt($max)) - 1;

# Create a new image
my $img = Imager->new(xsize => $limit * 2, ysize => $limit + 1);
my $red = Imager::Color->new(255, 0, 0);

for my $m (0 .. $limit) {
    my $x = $limit - $m;
    for my $n ($j .. $m**2) {
        if (exists $data{$j}) {
            $img->setpixel(x => $x, y => $m, color => $red);
        }
        ++$x;
        ++$j;
    }
}

$img->write(file => 'prime_triangle.png');
