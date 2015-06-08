#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 08 June 2015
# http://github.com/trizen

#
## Generate a "horsie" image based on simple mathematics.
#

use 5.010;
use strict;
use warnings;
use GD::Simple;

my $max   = 3_500_000;
my $limit = int(sqrt($max));

# create a new image
my $img = GD::Simple->new($limit * 6, $limit * 6);

# move to right
$img->moveTo($limit * 4, $limit * 4);

my $j = 1;
foreach my $i (1 .. $limit) {

    my $t = $i;
    for my $n ($j .. $i**2) {
        $img->line(1);
        $img->turn($t);
        $t += $i;
        ++$j;
    }

    ++$i;
}

open my $fh, '>:raw', "horsie_art.png";
print $fh $img->png;
close $fh;
