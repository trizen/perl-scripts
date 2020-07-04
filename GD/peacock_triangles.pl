#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 26 August 2015
# https://github.com/trizen

#
## Generate an interesting image containing some triangles with "peacock tails"
#

use 5.010;
use strict;
use warnings;
use GD::Simple;

my $max   = 1200000;               # duration: about 6 seconds
my $limit = int(sqrt($max)) - 1;

my $img = GD::Simple->new($limit * 12, $limit * 4);

my $i = 1;
my $j = 1;

$img->turn(0.001);

say "** Generating...";
for my $m (reverse(0 .. $limit)) {
    $img->moveTo($m * 12, 2 * ($i - 1));

    for my $n ($j .. $i**2) {
        $img->line(1);
        ++$j;
    }
    ++$i;
}

open my $fh, '>:raw', "peacock_triangles.png";
print $fh $img->png;
close $fh;
