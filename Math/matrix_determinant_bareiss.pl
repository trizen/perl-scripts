#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 20 November 2016
# https://github.com/trizen

# The Bareiss algorithm for computing the determinant of a (square) matrix.

# Algorithm from:
#   http://apidock.com/ruby/v1_9_3_125/Matrix/determinant_bareiss

# See also:
#   https://en.wikipedia.org/wiki/Bareiss_algorithm

use 5.010;
use strict;
use warnings;

use List::Util qw(first);

sub det {
    my ($m) = @_;

    my @m = map { [@$_] } @$m;

    my $sign  = +1;
    my $pivot = 1;
    my $end   = $#m;

    foreach my $k (0 .. $end) {
        my @r = ($k + 1 .. $end);

        my $prev_pivot = $pivot;
        $pivot = $m[$k][$k];

        if ($pivot == 0) {
            my $i = (first { $m[$_][$k] } @r) // return 0;
            @m[$i, $k] = @m[$k, $i];
            $pivot = $m[$k][$k];
            $sign  = -$sign;
        }

        foreach my $i (@r) {
            foreach my $j (@r) {
                (($m[$i][$j] *= $pivot) -= $m[$i][$k] * $m[$k][$j]) /= $prev_pivot;
            }
        }
    }

    $sign * $pivot;
}

my $matrix = [
    [2, -1,  5,  1],
    [3,  2,  2, -6],
    [1,  3,  3, -1],
    [5, -2, -3,  3],
];

say det($matrix);       #=> 684
