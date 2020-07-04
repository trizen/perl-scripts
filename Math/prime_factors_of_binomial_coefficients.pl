#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 25 August 2016
# Website: https://github.com/trizen

# An efficient algorithm for prime factorization of binomial coefficients.

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(forprimes todigits vecsum);

sub factorial_power ($n, $p) {
    ($n - vecsum(todigits($n, $p))) / ($p - 1);
}

#
# Example for:
#     binomial(100, 50)
#
# which is equivalent with:
#    100! / (100-50)! / 50!
#

my $n = 100;
my $k = 50;
my $j = $n - $k;

my @factors;

forprimes {
    my $p = factorial_power($n, $_);

    if ($_ <= $k) {
        $p -= factorial_power($k, $_);
    }

    if ($_ <= $j) {
        $p -= factorial_power($j, $_);
    }

    if ($p > 0) {
        push @factors, ($_) x $p;
    }
} $n;

say "Prime factors of binomial($n, $k) = (@factors)";
