#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 26 May 2015
# http://github.com/trizen

#
## Generate a complex shape using basic mathematics.
#

use 5.010;
use strict;
use warnings;
use GD::Simple;

my $max   = 1200000;
my $limit = int(sqrt($max)) - 1;

# create a new image
my $img = GD::Simple->new($limit * 2, $limit + 1);

# move to right
$img->moveTo($limit * 1.5, $limit / 2);

my $i = 1;
my $j = 1;

for my $m (reverse(0 .. $limit)) {

    for my $n ($j .. $i**2) {
        $img->line(1);
        $img->turn($n**2 / $i);
        ++$j;
    }

    ++$i;
}

open my $fh, '>:raw', "abstract_map.png";
print $fh $img->png;
close $fh;
