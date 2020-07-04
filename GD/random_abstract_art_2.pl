#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 08 June 2015
# http://github.com/trizen

#
## Generate complex random art based on simple mathematics.
#

use 5.010;
use strict;
use warnings;
use GD::Simple;

my $max   = 1_000_000;
my $limit = int(sqrt($max));

# create a new image
my $img = GD::Simple->new($limit * 3, $limit * 3);

# move to the center
$img->moveTo($limit * 1.5, $limit * 1.5);

my $i = 1;
my $j = 1;

for my $m (map { rand($limit) - rand($limit) } (1 .. $limit)) {

    for my $n ($j .. $i**2) {
        $img->line(1);
        $img->turn($n**2 / $m);
        ++$j;
    }

    ++$i;
}

open my $fh, '>:raw', "random_abstract_art_2.png";
print $fh $img->png;
close $fh;
