#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 21 May 2015
# http://github.com/trizen

#
## Generate a triangle with the collatz numbers
#

# Each pixel is highlighted based on the path frequency;
# For example: 4 2 1 are the most common number paths and
# they have the highest frequency and a hotter color (reddish),
# while a less frequent path is represented by colder color (bluish);
# in the middle lies the average frequency, represented by a greenish color.

use 5.010;
use strict;
use warnings;

use GD::Simple;
use List::Util qw(max sum);

my %collatz;

sub collatz {
    my ($n) = @_;
    while ($n > 1) {
        if ($n % 2 == 0) {
            $n /= 2;
        }
        else {
            $n = $n * 3 + 1;
        }
        $collatz{$n}++;
    }
    return 1;
}

my $k = 10000;    # maximum number (duration: about 2 minutes)

for my $i (1 .. $k) {
    collatz($i);
}

my $i = 1;
my $j = 1;

my $avg = sum(values %collatz) / scalar(keys %collatz);

say "Avg: $avg";

my $max   = max(keys %collatz);
my $limit = int(sqrt($max)) - 1;

# create a new image
my $img = GD::Simple->new($limit * 2, $limit + 1);

my $white = 0;
for my $m (reverse(0 .. $limit)) {
    $img->moveTo($m, $i - 1);

    for my $n ($j .. $i**2) {
        if (exists $collatz{$j}) {

            my $v     = $collatz{$j};
            my $ratio = $avg / $v;

            my $red  = 255 - int(255 * $ratio);
            my $blue = 255 - int(255 / $ratio);

            $red  = 0 if $red < 0;
            $blue = 0 if $blue < 0;

            $img->fgcolor($red, 255 - (int(($red + $blue) / 2)), $blue);
            $white = 0;
        }
        elsif (not $white) {
            $white = 1;
            $img->fgcolor('white');
        }
        $img->line(1);
        ++$j;
    }
    ++$i;
}

open my $fh, '>:raw', 'collatz.png';
print $fh $img->png;
close $fh;
