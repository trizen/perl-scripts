#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 25 August 2016
# Website: https://github.com/trizen

# An efficient algorithm for prime factorization of binomial coefficients.

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
    my $p = power($n, $_);

    if ($_ <= $k) {
        $p -= power($k, $_);
    }

    if ($_ <= $j) {
        $p -= power($j, $_);
    }

    if ($p > 0) {
        push @factors, ($_) x $p;
    }
} $n;

say "Prime factors of binomial($n, $k) = (@factors)";
