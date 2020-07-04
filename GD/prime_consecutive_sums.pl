#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 18 August 2015
# Website: https://github.com/trizen

# This script plots the sums of consecutive primes

## Example:
# 2 + 2 = 4
# 3 + 2 = 5
# 3 + 3 = 6
# 5 + 2 = 7
# 5 + 3 = 8
# 5 + 5 = 10
# 7 + 2 = 9
# 7 + 3 = 10
# 7 + 5 = 12
# 7 + 7 = 14

# There are larger and larger overlaps, which suggests that
# the ratio between p(n+1) and p(n) get smaller and smaller.

use 5.010;
use strict;
use integer;

use Imager qw();
use ntheory qw(primes);

my $primes = primes(500);

my $xsize = @{$primes}**2 + 1;
my $ysize = $primes->[-1] * 2 + 1;

my ($x, $y) = (0, $ysize);
my $img = Imager->new(xsize => $xsize, ysize => $ysize);

my $white = Imager::Color->new('#ffffff');
my $red   = Imager::Color->new('#ff0000');

$img->box(filled => 1, color => $white);

foreach my $p1 (@{$primes}) {
    foreach my $p2 (@{$primes}) {
        foreach my $i (1 .. ($p1 + $p2)) {
            $img->setpixel(x => $x, y => $y - $i, color => $red);
        }
        $x += 1;
    }
    say $p1;
}

$img->write(file => "prime_sums.png");
