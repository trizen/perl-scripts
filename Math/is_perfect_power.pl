#!/usr/bin/perl

# Algorithm for testing if a given number `n` is a perfect
# power (i.e. can be expressed as: n = a^k with k > 1).

# The value of k is returned when n is an exact k-th power, 1 otherwise.

# Algorithm presented in the book:
#
#   Modern Computer Arithmetic
#           - by Richard P. Brent and Paul Zimmermann
#
use 5.010;
use strict;
use warnings;

use ntheory qw(logint rootint powint);
use experimental qw(signatures);

sub is_perfect_power ($n) {

    for (my $k = logint($n, 2) ; $k >= 2 ; --$k) {
        if (powint(rootint($n, $k), $k) == $n) {
            return $k;
        }
    }

    return 1;
}

say is_perfect_power(powint(1234, 14));    #=> 14
