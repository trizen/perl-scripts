#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 02 April 2016
# http://github.com/trizen

# Generate a triangle with highlighted numbers that satisfy: (isqrt(n)-1)! = isqrt(n)-1 (mod isqrt(n)).
# See also: http://oeis.org/A267016

use 5.010;
use strict;
use warnings;

use Imager;
use List::Util qw(max);
use Math::AnyNum qw(isqrt factorial);

my %data;

sub generate {
    my ($n) = @_;

    foreach my $i (1 .. $n) {
        my $j = isqrt($i);
        if (factorial($j - 1) % $j == $j - 1) {
            undef $data{$i + 1};
        }
    }

    return 1;
}

generate(400000);

my $i = 1;
my $j = 1;

my $max   = max(keys %data);
my $limit = int(sqrt($max)) - 1;

# Create a new image
my $img = Imager->new(xsize => $limit * 2, ysize => $limit + 1);
my $red = Imager::Color->new(255, 0, 0);

for my $m (0 .. $limit) {
    my $x   = $limit - $m;
    my $has = 0;
    for my $n ($j .. $m**2) {
        if (exists $data{$j}) {
            $img->setpixel(x => $x, y => $m, color => $red);
            $has ||= 1;
        }
        ++$x;
        ++$j;
    }
    say $m- 1 if $has;
}

$img->write(file => 'prime_stripe_triangle.png');
