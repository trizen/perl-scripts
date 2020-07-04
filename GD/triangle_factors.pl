#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 07 August 2016
# http://github.com/trizen

# A number triangle, where each number is highlighted with
# a different color based on the number of its prime factors.

use 5.010;
use strict;
use warnings;

use GD::Simple;
use ntheory qw(factor is_prime);
use List::Util qw(shuffle);

my @color_names = grep { !/white|gradient/ } shuffle(GD::Simple->color_names);

my $i = 1;
my $j = 1;

my $n = shift(@ARGV) // 1000000;    # duration: about 10 seconds
my $limit = int(sqrt($n)) - 1;

my %colors;

# create a new image
my $img = GD::Simple->new($limit * 2, $limit + 1);

my $white = 0;
for my $m (reverse(0 .. $limit)) {
    $img->moveTo($m, $i - 1);

    for my $n ($j .. $i**2) {
        my $f = factor($j);
        if ($f > 0 and $f <= @color_names) {
            $img->fgcolor($color_names[$f - 1]);
            $colors{$f} = $color_names[$f - 1];
        }
        else {
            $img->fgcolor('white');
        }
        $img->line(1);
        ++$j;
    }
    ++$i;
}

foreach my $key (sort { $a <=> $b } keys %colors) {
    say "$key\t : $colors{$key}";
}

open my $fh, '>:raw', 'triangle_factors.png';
print $fh $img->png;
close $fh;
