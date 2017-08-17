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

use 5.010;
use strict;
use warnings;

use ntheory qw(forprimes mulmod powmod);

sub power {
    my ($n, $p) = @_;

    my $count = 0;

    while ($n >= $p) {
        $count += int($n /= $p);
    }

    return $count;
}

sub sigma_of_unitary_divisors_of_factorial {
    my ($n, $k, $m) = @_;

    my $sigma = 1;

    forprimes {
        $sigma = mulmod($sigma, 1 + powmod($_, $k * power($n, $_), $m), $m);
    } $n;

    return $sigma;
}

my $k = 2;
my $n = 100;
my $m = 123456;

say sigma_of_unitary_divisors_of_factorial($n, $k, $m);   #=> 104128
