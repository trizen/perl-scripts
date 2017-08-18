#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 18 August 2017
# https://github.com/trizen

# Sum of the number of divisors, `d(k)`, for 1 <= k <= n.

# Formula with O(sqrt(n)) complexity:
#   Sum_{k=1..n} d(k) = (2 * Sum_{k=1..floor(sqrt(n))} floor(n/k)) - floor(sqrt(n))^2

use 5.010;
use strict;
use warnings;

sub sum_of_sigma0 {
    my ($n) = @_;

    my $s = int(sqrt($n));

    my $sum = 0;
    foreach my $k (1 .. $s) {
        $sum += int($n / $k);
    }

    $sum *= 2;
    $sum -= $s**2;

    return $sum;
}

say sum_of_sigma0(100);      #=> 482
say sum_of_sigma0(1234);     #=> 8979
say sum_of_sigma0(98765);    #=> 1151076
