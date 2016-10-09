#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 09 October 2016
# Website: https://github.com/trizen

# The period length after the decimal point of 1/n.
# This is defined only for integers prime to 10.

# Inspired by N. J. Wildberger's video:
#   https://www.youtube.com/watch?v=lMrz7ISoDGs

# See also:
#   http://oeis.org/A002329

use 5.010;
use strict;
use warnings;

use ntheory qw(divisors euler_phi powmod);

sub period_length_1_over_n {
    my ($n) = @_;

    my @divisors = divisors(euler_phi($n));

    foreach my $d (@divisors) {
        if (powmod(10, $d, $n) == 1) {
            return $d;
        }
    }

    return -1;
}

foreach my $n (1 .. 99) {
    my $l = period_length_1_over_n($n);
    printf("P(%2d) = %d\n", $n, $l) if $l != -1;
}
