#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 26 May 2015
# http://github.com/trizen

#
## Generate a wavy triangle using the power of 2.5 (scaled down by a trivial constant)
#

use 5.010;
use strict;
use warnings;
use GD::Simple;

sub generate {
    my ($n, $data) = @_;

    for my $i (0 .. $n) {
        $data->{int(($i**2.5) / 12000)} = 1;
    }

    return $n;
}

say "** Generating...";

my %data;
my $max = generate(500000, \%data);
my $limit = int(sqrt($max)) - 1;

# create a new image
my $img = GD::Simple->new($limit * 2, $limit + 1);

my $i = 1;
my $j = 1;

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

open my $fh, '>:raw', 'wavy_triangle.png';
print $fh $img->png;
close $fh;
