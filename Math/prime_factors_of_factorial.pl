#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 18 July 2016
# Website: https://github.com/trizen

# A shortcut algorithm for finding the factors of n!
# without computing the factorial in the first place.

# Example:
#  The factors of 6! are [2, 2, 2, 2, 3, 3, 5].

use 5.010;
use strict;
use warnings;

use ntheory qw(forprimes);

sub power {
    my ($n, $p) = @_;

    my $s = 0;
    while ($n >= $p) {
        $s += int($n /= $p);
    }

    $s;
}

sub factorial_factors {
    my ($n) = @_;
    my @factors;

    forprimes {
        push @factors, ($_) x power($n, $_);
    } $n;

    @factors;
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
