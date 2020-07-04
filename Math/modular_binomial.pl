#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 08 February 2017
# Website: https://github.com/trizen

# Algorithm for binomial(n, k) mod m.

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(forprimes powmod vecsum todigits);

sub factorial_power ($n, $p) {
    ($n - vecsum(todigits($n, $p))) / ($p - 1);
}

sub modular_binomial ($n, $k, $m) {

    my $j    = $n - $k;
    my $prod = 1;

    forprimes {
        my $p = factorial_power($n, $_);

        if ($_ <= $k) {
            $p -= factorial_power($k, $_);
        }

        if ($_ <= $j) {
            $p -= factorial_power($j, $_);
        }

        if ($p > 0) {
            $prod *= ($p == 1) ? ($_ % $m) : powmod($_, $p, $m);
            $prod %= $m;
        }
    } $n;

    $prod;
}

say modular_binomial(100, 50, 139);        #=> 71
say modular_binomial(124, 42, 1234567);    #=> 395154
