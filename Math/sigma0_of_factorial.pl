#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 25 July 2017
# https://github.com/trizen

# An efficient algorithm for computing sigma0(n!).

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(forprimes todigits vecsum);

sub factorial_power ($n, $p) {
    ($n - vecsum(todigits($n, $p))) / ($p - 1);
}

sub sigma0_of_factorial {
    my ($n) = @_;

    my $sigma0 = 1;

    forprimes {
        $sigma0 *= 1 + factorial_power($n, $_);
    } $n;

    return $sigma0;
}

say sigma0_of_factorial(10);     # 270
say sigma0_of_factorial(100);    # 39001250856960000
