#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 09 February 2017
# https://github.com/trizen

# Counts the number of squarefree numbers in the range [1, n].

# See also:
#   https://oeis.org/A053462
#   https://projecteuler.net/problem=193
#   https://en.wikipedia.org/wiki/Square-free_integer
#   https://en.wikipedia.org/wiki/M%C3%B6bius_function

use 5.010;
use strict;
use integer;

use ntheory qw(moebius sqrtint);

sub squarefree_count {
    my ($n) = @_;

    my $k     = 1;
    my $count = 0;

    foreach my $m (moebius(1, sqrtint($n))) {
        $count += $m * ($n / ($k++)**2);
    }

    return $count;
}

say squarefree_count(10**9);    #=> 607927124
