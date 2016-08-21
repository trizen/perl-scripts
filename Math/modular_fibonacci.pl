#!/usr/bin/perl

# Date: 21 August 2016
# Website: https://github.com/trizen

# An efficient algorithm for computing large Fibonacci numbers, modulus some n.
# Algorithm from: http://codeforces.com/blog/entry/14516

use 5.010;
use strict;
use integer;
use warnings;

use Memoize qw(memoize);

memoize('f');

sub f {
    my ($n, $mod) = @_;

    $n <= 1 && return 1;
    my $k = int($n/2);

    $n % 2 == 0
        ? (f($k, $mod) * f($k    , $mod) + f($k - 1, $mod) * f($k - 1, $mod)) % $mod
        : (f($k, $mod) * f($k + 1, $mod) + f($k - 1, $mod) * f($k    , $mod)) % $mod
}

sub fibmod {
    my ($n, $mod) = @_;
    $n <= 1 && return $n;
    f($n-1, $mod);
}

say fibmod(1000, 10**4);
