#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 19 December 2016
# https://github.com/trizen

# Implementation of the binomial theorem.

# Defined as:
#   (a + b)^n = sum(g(k) * a^(n-k) * b^k, {k=0, n})
#
# where g(k) is:
#   g(0) = 1
#   g(k) = (n - k + 1) * g(k-1) / k

use 5.010;
use strict;
use warnings;

no warnings 'recursion';

#
## The binomial coefficient: (n, k)
#
sub g {
    my ($n, $k) = @_;
    $k == 0 ? 1 : ($n - $k + 1) * g($n, $k - 1) / $k;
}

#
## Binomial summation for (a + b)^n
#
sub binomial_sum {
    my ($a, $b, $n) = @_;
    my $sum = 0;
    foreach my $k (0 .. $n) {
        $sum += g($n, $k) * $a**($n - $k) * $b**$k;
    }
    return $sum;
}

#
## Example for (1 + 1/30)^30
#

my $a = 1;
my $b = 1/30;
my $n = 30;

say binomial_sum($a, $b, $n);       #=> 2.6743187758703
