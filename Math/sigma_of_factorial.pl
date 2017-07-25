#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 25 July 2017
# https://github.com/trizen

# An efficient algorithm for computing sigma_k(n!), where k > 0.

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

sub sigma_of_factorial {
    my ($n, $a) = @_;

    my $sigma = 1;

    forprimes {
        my $p = $_;
        my $k = power($n, $p);
        $sigma *= (($p**($a * ($k + 1)) - 1) / ($p**$a - 1));
    } $n;

    return $sigma;
}

say sigma_of_factorial(10, 1);    # sigma_1(10!) = 15334088
say sigma_of_factorial(10, 2);    # sigma_2(10!) = 20993420690550
say sigma_of_factorial( 8, 3);    # sigma_3( 8!) = 78640578066960
