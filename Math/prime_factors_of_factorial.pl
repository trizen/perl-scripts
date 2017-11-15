#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 18 July 2016
# Website: https://github.com/trizen

# A shortcut algorithm for finding the factors of n!
# without computing the factorial in the first place.

# Example:
#  The factors of 6! are [2, 2, 2, 2, 3, 3, 5].

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(forprimes vecsum todigits);

sub factorial_power ($n, $p) {
    ($n - vecsum(todigits($n, $p))) / ($p - 1);
}

sub factorial_factors ($n) {
    my @factors;

    forprimes {
        push @factors, ($_) x factorial_power($n, $_);
    } $n;

    return @factors;
}

for (1 .. 10) {
    say "factors($_!) = [", join(',', factorial_factors($_)), "]";
}

__END__
factors(1!) = []
factors(2!) = [2]
factors(3!) = [2,3]
factors(4!) = [2,2,2,3]
factors(5!) = [2,2,2,3,5]
factors(6!) = [2,2,2,2,3,3,5]
factors(7!) = [2,2,2,2,3,3,5,7]
factors(8!) = [2,2,2,2,2,2,2,3,3,5,7]
factors(9!) = [2,2,2,2,2,2,2,3,3,3,3,5,7]
factors(10!) = [2,2,2,2,2,2,2,2,3,3,3,3,5,5,7]
