#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 12 December 2016
# https://github.com/trizen

# Levenshtein distance (iterative implementation).

# See also:
#   https://en.wikipedia.org/wiki/Levenshtein_distance

use 5.010;
use strict;
use warnings;

use List::Util qw(min);

sub leven {
    my ($s, $t) = @_;

    my $tl = length($t);
    my $sl = length($s);

    my @d = ([0 .. $tl], map { [$_] } 1 .. $sl);

    foreach my $i (0 .. $sl - 1) {
        foreach my $j (0 .. $tl - 1) {
            $d[$i + 1][$j + 1] =
              substr($s, $i, 1) eq substr($t, $j, 1)
              ? $d[$i][$j]
              : 1 + min($d[$i][$j + 1], $d[$i + 1][$j], $d[$i][$j]);
        }
    }

    $d[-1][-1];
}

say leven('rosettacode', 'raisethysword');
