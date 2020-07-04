#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 18 August 2017
# https://github.com/trizen

# A simple implementation of the arithmetic derivative function for positive integers.

# See also:
#   https://projecteuler.net/problem=484

use 5.016;
use strict;
use warnings;

use ntheory qw(factor);

sub arithmetic_derivative {
    my ($n) = @_;

    my @factors = factor($n);

    my $sum = 0;
    foreach my $p (@factors) {
        $sum += $n / $p;
    }

    return $sum;
}

say arithmetic_derivative(1234);            #=> 619
say arithmetic_derivative(479001600);       #=> 3496919040
say arithmetic_derivative(162375475128);    #=> 298100392484
