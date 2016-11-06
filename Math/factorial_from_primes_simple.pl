#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 18 July 2016
# Website: https://github.com/trizen

# A fast algorithm, based on powers of primes,
# for exactly computing very large factorials.

use 5.010;
use strict;
use warnings;

use bigint try => 'GMP';
use ntheory qw(forprimes);

sub power {
    my ($n, $p) = @_;

    my $s = 0;
    while ($n >= $p) {
        $s += int($n /= $p);
    }

    $s;
}

sub factorial {
    my ($n) = @_;

    my $f = 1;

    forprimes {
        $f *= $_**power($n, $_);
    } $n;

    return $f;
}

for my $n (0 .. 50) {
    say "$n! = ", factorial($n);
}
