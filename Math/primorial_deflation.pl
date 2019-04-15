#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 15 April 2019
# https://github.com/trizen

# Represent a given number as a product of primorials (if possible).

# The sequence of numbers that can be represented as a product of primorials, is given by:
#   https://oeis.org/A025487

# Among other terms, the sequence includes the factorials and the highly composite numbers.

# See also:
#   https://oeis.org/A181815 -- "primorial deflation" of A025487(n)
#   https://oeis.org/A108951 -- "primorial inflation" of n

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use ntheory qw(factor);
use Math::AnyNum qw(factorial primorial prod);

sub primorial_deflation ($n) {

    my @terms;

    while ($n > 1) {

        my $g = (factor($n))[-1];
        my $p = primorial($g);

        $n /= $p;
        $n->is_int || return undef;

        push @terms, $g;
    }

    return prod(@terms);
}

my @arr = map { primorial_deflation(factorial($_)) } 0 .. 15;    # https://oeis.org/A307035

say join ', ', @arr;                                                   #=> 1, 1, 2, 3, 12, 20, 60, 84, 672, 1512, 5040, 7920, 47520, 56160, 157248
say join ', ', map { prod(map { primorial($_) } factor($_)) } @arr;    #=> 1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880, 3628800, 39916800, 479001600, 6227020800, 87178291200
