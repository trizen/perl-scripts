#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 07 June 2015
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
my $img = GD::Simple->new($limit * 4, $limit * 2);

# move to right
$img->moveTo($limit * 3.20, $limit);

my $j = 1;
foreach my $i (1 .. $limit) {

    for my $n ($j .. $i**2) {
        $img->line(2);
        $img->turn($n**2 / $i);
        ++$j;
    }

}

open my $fh, '>:raw', "abstract_map.png";
print $fh $img->png;
close $fh;
