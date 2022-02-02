#!/usr/bin/perl

# Author: Trizen
# Date: 02 February 2022
# http://github.com/trizen

# Generate a random art, using the digits of Pi in a given base.

# See also:
#   https://yewtu.be/watch?v=tkC1HHuuk7c

use 5.010;
use strict;
use warnings;

use GD::Simple;
use ntheory qw(Pi todigits);

my $width  = 4000;
my $height = 5000;

# create a new image
my $img = GD::Simple->new($width, $height);

# move to the center
$img->moveTo($width >> 1, $height >> 1);

my $digits    = 100000;    # how many of digits of pi to use
my $base      = 4;         # base
my $line_size = 7;         # size of the line

my $pi = join '', Pi($digits);
$pi =~ s/\.//;

my @digits = todigits($pi, $base);
my $theta  = 360 / $base;

for my $d (@digits) {
    $img->turn($theta * $d);
    $img->line($line_size);
}

open my $fh, '>:raw', "pi_abstract_art.png";
print $fh $img->png;
close $fh;
