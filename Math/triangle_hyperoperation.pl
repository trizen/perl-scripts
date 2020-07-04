#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 16 October 2016
# Website: https://github.com/trizen

# Efficient implementation of the triangle hyperoperation, modulo some n.

# For definition, see:
#   https://www.youtube.com/watch?v=sW_IkMQEAwo

# See also:
#   https://www.youtube.com/watch?v=9DeOnCKfSuY

use strict;
use integer;
use warnings;

use ntheory qw(powmod forprimes);

sub triangle {
    my ($n, $k, $mod) = @_;
    return $n if $k == 1;
    powmod($n, triangle($n, $k - 1, $mod), $mod);
}

# let z = triangle(10, 10) + 23
# Question: what are the prime factors of z?

forprimes {
    my $r = (triangle(10, 10, ${_}) + 23) % ${_};
    print "$_ divides z\n" if $r == 0;
} 1e5;
