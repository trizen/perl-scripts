#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 26 May 2015
# http://github.com/trizen

#
## Generate a random pattern triangle
#

use 5.010;
use strict;
use warnings;
use GD::Simple;

sub generate {
    my ($n, $data) = @_;

    foreach my $i (1 .. $n) {
        if (rand() < 0.5) {
            $data->{$i} = 1;
        }
    }

    return $n;
}

say "** Generating...";

my %data;
my $max = generate(300000, \%data);
my $limit = int(sqrt($max)) - 1;

# create a new image
my $img = GD::Simple->new($limit * 2, $limit + 1);

my $i = 1;
my $j = 1;

for my $m (reverse(0 .. $limit)) {
    $img->moveTo($m, $i - 1);

    for my $n ($j .. $i**2) {
        $img->fgcolor(exists($data{$j}) ? 'red' : 'black');
        $img->line(1);
        ++$j;
    }
    ++$i;
}

open my $fh, '>:raw', "random_noise_triangle.png";
print $fh $img->png;
close $fh;
