#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 08 June 2015
# http://github.com/trizen

#
## Generate a circular triangle based on triangular numbers.
#

use 5.010;
use strict;
use warnings;
use GD::Simple;

my $from = 0;
my $step = 1;

my $max   = 3_000_000;
my $limit = int(sqrt($max));

# create a new image
my $img = GD::Simple->new($limit * 6, $limit * 6);

# move to right
$img->moveTo($limit * 2.75, $limit * 1.75);

my $j = 1;
foreach my $i (1 .. $limit) {

    for my $n ($j .. $i**2) {
        $img->line(1);
        $img->turn(($from + $i) * (($i - $from) / $step + 1) / 2);
        ++$j;
    }

    ++$i;
}

open my $fh, '>:raw', "circular_triangle.png";
print $fh $img->png;
close $fh;
