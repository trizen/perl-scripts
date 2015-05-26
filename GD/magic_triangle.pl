#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 25 May 2015
# http://github.com/trizen

#
## Generate a magic triangle using a simple series of numbers
#

use 5.010;
use strict;
use warnings;

use GD::Simple;
use List::Util qw(max);

my %data;

sub generate {
    my ($n) = @_;

    my $sum = 0;    # will be incremented by 1, 2, 3, ...

    foreach my $i (1 .. $n) {
        $sum += $i;
        $data{$sum} = 1;
    }

    return 1;
}

generate(400);

my $i = 1;
my $j = 1;

my $max   = max(keys %data);
my $limit = int(sqrt($max)) - 1;

# create a new image
my $img = GD::Simple->new($limit * 2, $limit + 1);

my $black = 0;
for my $m (reverse(0 .. $limit)) {
    $img->moveTo($m, $i - 1);

    for my $n ($j .. $i**2) {
        if (exists $data{$j}) {
            $black = 0;
            $img->fgcolor('red');
        }
        elsif (not $black) {
            $black = 1;
            $img->fgcolor('black');
        }
        $img->line(1);
        ++$j;
    }
    ++$i;
}

open my $fh, '>:raw', 'magic_triangle.png';
print $fh $img->png;
close $fh;
