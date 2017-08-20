#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 20 August 2017
# https://github.com/trizen

# Sum of the sigma_2(k) function, for 1 <= k <= n, where `sigma_2(k)` is `Sum_{d|k} d^2`.

# Algorithm with O(sqrt(n)) time complexity, due to Aleksey (https://projecteuler.net/thread=401).

use 5.010;
use strict;
use warnings;

use ntheory qw(sqrtint);

sub f {
    my ($n) = @_;
    $n * ($n + 1) * (2 * $n + 1) / 6;
}

sub sum_of_sum_of_squared_divisors {
    my ($n) = @_;

    my $s = sqrtint($n);
    my $u = int($n / ($s + 1));

    my $sum = 0;

    foreach my $k (1 .. $u) {
        $sum += $k**2 * int($n / $k);
    }

    foreach my $k (1 .. $s) {
        $sum += $k * (f(int($n / $k)) - f(int($n / ($k + 1))));
    }

    return $sum;
}

foreach my $n (1 .. 20) {
    say sum_of_sum_of_squared_divisors($n);
}
