#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 17 September 2016
# Website: https://github.com/trizen

# Sum of increasing powers in constant base.

# Example:
#    ∑b^i for 0 ≤ i ≤ n == cf(b, n)
#
# where `b` can be any real number != 1.

use 5.010;
use strict;
use warnings;

sub cf {
    my ($base, $n) = @_;
    ($base ** ($n+1) - 1) / ($base-1);
}

say cf(3, 13);
say cf(-10.5, 4);
say cf(3.1415926535897932384626433832795, 10);
