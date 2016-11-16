#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13 August 2016
# Website: https://github.com/trizen

# Display a matrix as a rectangle packed with circles.

# Brighter circles represent larger numerical values,
# while dimmer circles represent smaller numerical values.

use 5.010;
use strict;
use warnings;

use Imager;
use List::MoreUtils qw(minmax);

my @matrix = (
              [131, 673, 234, 103, 18],
              [201, 96,  342, 965, 150],
              [630, 803, 746, 422, 111],
              [537, 699, 497, 121, 956],
              [805, 732, 524, 37,  331],
             );

#<<<
# Reading a matrix from the standard input.
#~ @matrix = ();
#~ while(<>) {
    #~ chomp;
    #~ push @matrix, [split(/,/, $_)];
#~ }
#>>>

my $max_color    = 2**16 - 1;
my $scale_factor = 10;
my $radius       = $scale_factor / atan2(0, -'inf');
my $space        = $radius / 2;

my $img = Imager->new(
                      xsize    => @{$matrix[0]} * $scale_factor,
                      ysize    => @matrix * $scale_factor,
                      channels => 3,
                     );

my ($min, $max) = minmax(map { @$_ } @matrix);

foreach my $i (0 .. $#matrix) {
    my $row = $matrix[$i];
    foreach my $j (0 .. $#{$row}) {
        my $cell = $row->[$j];

        my $value = int($max_color / ($max - $min) * ($cell - $min));
        my $color = Imager::Color->new(sprintf("#%06x", $value));

        $img->circle(
                     r     => $radius,
                     x     => int($j * $scale_factor + $radius + $space),
                     y     => int($i * $scale_factor + $radius + $space),
                     color => $color,
                    );
    }
}

$img->write(file => 'matrix_circle.png');
