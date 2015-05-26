#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 26 May 2015
# http://github.com/trizen

#
## Generate a random-looking pattern triangle (but it's not random!)
#

use 5.010;
use strict;
use warnings;
use GD::Simple;

sub generate {
    my ($n, $data) = @_;

    my $sum = 0;
    foreach my $i (1 .. $n) {
        if ($sum >= $i) {
            $data->{$sum} = 1;
            $sum -= int(sqrt($i) + 1);    # this is the "random" line
        }
        else {
            $sum += $i;
        }
    }

    return $n;
}

say "** Generating...";

my %data;
my $max = generate(100000, \%data);
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

open my $fh, '>:raw', "random_looking_triangle.png";
print $fh $img->png;
close $fh;
