#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 29 November 2016
# https://github.com/trizen

# A recursive function that represents the Golomb's sequence.

# See also:
#   http://oeis.org/A001462
#   https://projecteuler.net/problem=341
#   https://en.wikipedia.org/wiki/Golomb_sequence

use 5.020;
use strict;
use warnings;

no warnings qw(recursion);

use experimental qw(signatures);
use Memoize qw(memoize);

memoize('G');    # this will save time

sub G($n) {
    $n == 1 ? 1 : 1 + G($n - G(G($n - 1)));
}

say "G(1000) = ", G(1000);
