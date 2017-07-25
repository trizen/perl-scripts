#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 25 July 2017
# https://github.com/trizen

# An efficient algorithm for computing sigma0(n!).

use 5.010;
use strict;
use warnings;

use ntheory qw(forprimes);

sub power {
    my ($n, $p) = @_;

    my $count = 0;

    while ($n >= $p) {
        $count += int($n /= $p);
    }

    return $count;
}

sub sigma0_of_factorial {
    my ($n) = @_;

    my $sigma0 = 1;

    forprimes {
        $sigma0 *= 1 + power($n, $_);
    } $n;

    return $sigma0;
}

say sigma0_of_factorial(10);     # 270
say sigma0_of_factorial(100);    # 39001250856960000
