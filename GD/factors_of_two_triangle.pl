#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 09 August 2016
# http://github.com/trizen

#
## Generates a number triangle, highlighting the number of
## factors of two with a different color for each number n.
#

use 5.010;
use strict;
use warnings;

use GD::Simple;
use ntheory qw(factor);
use List::Util qw(max shuffle);

my @colors = shuffle(grep { !/black|gradient/ } GD::Simple->color_names);

my %data;

sub generate {
    my ($n) = @_;

    foreach my $i (0 .. $n) {
        $data{$i} = grep { $_ == 2 } factor($i);
    }

    return 1;
}

generate(1000000);      # takes about 10 seconds

my $i = 1;
my $j = 1;

my $max   = max(keys %data);
my $limit = int(sqrt($max)) - 1;

my $img = GD::Simple->new($limit * 2, $limit + 1);

for my $m (reverse(0 .. $limit)) {
    $img->moveTo($m, $i - 1);

    for my $n ($j .. $i**2) {
        if ($data{$j} > 0) {
            $img->fgcolor($colors[$data{$j}]);
        }
        else {
            $img->fgcolor('black');
        }
        $img->line(1);
        ++$j;
    }
    ++$i;
}

open my $fh, '>:raw', 'factors_of_two.png';
print $fh $img->png;
close $fh;
