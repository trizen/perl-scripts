#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 17 August 2017
# https://github.com/trizen

# An efficient algorithm for computing:
#
#      --                 --
#      |       ---         |
#      |       \           |
#      |       /    d^k    |  (mod m)
#      |       ---         |
#      |       d|n!        |
#      |  gcd(d, n!/d) = 1 |
#      --                 --
#

# See also:
#   https://projecteuler.net/problem=429

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(forprimes mulmod powmod vecsum todigits);

sub factorial_power ($n, $p) {
    ($n - vecsum(todigits($n, $p))) / ($p - 1);
}

sub sigma_of_unitary_divisors_of_factorial ($n, $k, $m) {

    my $sigma = 1;

    forprimes {
        $sigma = mulmod($sigma, 1 + powmod($_, $k * factorial_power($n, $_), $m), $m);
    } $n;

    return $sigma;
}

my $k = 2;
my $n = 100;
my $m = 123456;

say sigma_of_unitary_divisors_of_factorial($n, $k, $m);   #=> 104128
