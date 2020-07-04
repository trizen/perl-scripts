#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 18 April 2015
# http://github.com/trizen

# A number triangle, with the primes highlighted in blue
# (there are some lines that have more primes than others)

# Inspired by: https://www.youtube.com/watch?v=iFuR97YcSLM

use 5.010;
use strict;
use warnings;

use GD::Simple;
use ntheory qw(is_prime);

my $i   = 1;
my $max = 2000;    # duration: about 11 seconds

# create a new image
my $img = GD::Simple->new($max, $max);

my $white = 0;
$img->fgcolor('blue');

foreach my $x (1 .. $max) {

    $img->moveTo(0, $x - 1);

    foreach my $y (1 .. $x) {
        if (is_prime($i)) {
            $white = 0;
            $img->fgcolor('blue');
        }
        elsif (not $white) {
            $white = 1;
            $img->fgcolor('white');
        }

        $img->line(1);
        ++$i;
    }
}

open my $fh, '>:raw', 'triangle_primes_2.png';
print $fh $img->png;
close $fh;
