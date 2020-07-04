#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 21 February 2018
# https://github.com/trizen

# Simple numerical approximation for definite integrals.

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

sub integral ($from, $to, $expr, $dx = 0.0001) {
    my $sum = 0;

    for (my $x = $from ; $x <= $to ; $x += $dx) {
        $sum += $expr->($x) * $dx;
    }

    return $sum;
}

say integral(0, atan2(0, -1), sub ($x) { sin($x) });              # 1.99999999867257
say integral(2,  100, sub ($x) { 1 / log($x) });                  # 29.0810390821689
say integral(-3, 5,   sub ($x) { 10 * $x**3 + $x * cos($x) });    # 1355.97975127903
