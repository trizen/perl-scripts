#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 08 February 2017
# Website: https://github.com/trizen

# Algorithm for binomial(n, k) mod m.

use 5.010;
use strict;
use warnings;

use ntheory qw(forprimes powmod);

sub power {
    my ($n, $p) = @_;

    my $s = 0;
    while ($n >= $p) {
        $s += int($n /= $p);
    }

    $s;
}

sub modular_binomial {
    my ($n, $k, $m) = @_;

    my $j = $n - $k;
    my $prod = 1;

    forprimes {
        my $p = power($n, $_);

        if ($_ <= $k) {
            $p -= power($k, $_);
        }

        if ($_ <= $j) {
            $p -= power($j, $_);
        }

        if ($p > 0) {
            $prod *= powmod($_, $p, $m);
            $prod %= $m;
        }
    } $n;

    $prod;
}

say modular_binomial(100, 50, 139);     #=> 71
