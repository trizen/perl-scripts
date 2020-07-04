#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 12 December 2016
# https://github.com/trizen

# Levenshtein distance (recursive implementation).

# See also:
#   https://en.wikipedia.org/wiki/Levenshtein_distance

use 5.010;
use strict;
use warnings;

use List::Util qw(min);
use Memoize qw(memoize);

memoize('leven');

sub leven {
    my ($s, $t) = @_;

    return length($t) if $s eq '';
    return length($s) if $t eq '';

    my ($s1, $t1) = (substr($s, 1), substr($t, 1));

    (substr($s, 0, 1) eq substr($t, 0, 1))
      ? leven($s1, $t1)
      : min(
            leven($s1, $t1),
            leven($s,  $t1),
            leven($s1, $t ),
        ) + 1;
}

say leven('rosettacode', 'raisethysword');
