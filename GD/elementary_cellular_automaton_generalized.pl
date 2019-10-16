#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 16 October 2019
# https://github.com/trizen

# Generalization of the elementary cellular automaton, by using `n` color-states and looking at `k` neighbors left-to-right.

# For example, a value of `n = 3` and `k = 2` uses three different color-states and looks at 2 neighbors to the left and 2 neighbors to the right.

# See also:
#   https://en.wikipedia.org/wiki/Cellular_automaton
#   https://en.wikipedia.org/wiki/Elementary_cellular_automaton
#   http://rosettacode.org/wiki/Elementary_cellular_automaton

# YouTube lectures:
#   https://www.youtube.com/watch?v=S3tYzCPuVsA
#   https://www.youtube.com/watch?v=pGGIE5uhPRQ

use 5.020;
use strict;
use warnings;

use Imager;
use ntheory qw(:all);
use experimental qw(signatures);
use Algorithm::Combinatorics qw(variations_with_repetition);

sub automaton ($n, $k, $iter, $rule, $cells = [1]) {

    my %colors = (
                  0 => 'black',
                  1 => 'white',
                  2 => 'red',
                  3 => 'blue',
                  4 => 'green',
                  5 => 'yellow',
                 );

    say "Generating $n x $k with rule $rule.";

    my $size = $iter;
    my $img  = Imager->new(xsize => $size, ysize => $size >> 1);

    my @states = variations_with_repetition([0 .. $n - 1], 2 * $k + 1);
    my @digits = reverse todigits($rule, $n);

    my @lookup;

    foreach my $i (0 .. $#states) {
        $lookup[fromdigits($states[$i], $n)] = $digits[$i] // 0;
    }

    my @padding         = (0) x (($iter - scalar(@$cells)) >> 1);
    my @cells           = (@padding, @$cells, @padding);
    my @neighbors_range = (-$k .. $k);

    my $len = scalar(@cells);

    for my $i (0 .. ($iter >> 1) - 1) {

        foreach my $j (0 .. $#cells) {
            if ($cells[$j]) {
                $img->setpixel(
                               y     => $i,
                               x     => $j,
                               color => $colors{$cells[$j]},
                              );
            }
        }

        @cells = @lookup[
          map {
              my $i = $_;
              fromdigits([map { $cells[($i + $_) % $len] } @neighbors_range], $n)
          } 0 .. $#cells
        ];
    }

    return $img;
}

automaton(2, 1, 1000, "30")->write(file => "rule_30.png");
automaton(3, 1, 1000, "3760220742240")->write(file => "sierpinski_3x1.png");
automaton(3, 1, 1000, "2646595889467")->write(file => "random_3x1.png");
automaton(2, 2, 1000, "413000741")->write(file => "random_2x2.png");
automaton(3, 1, 1000, "4018294395539")->write(file => "random_3x1-2.png");
