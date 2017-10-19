#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 18 October 2017
# https://github.com/trizen

# Finds the value of `k` such that:
#   (x/(k-1))^(k-1) < (x/k)^k > (x/(k+1))^(k+1)

# Closed-form expression would be:
#   f(x) = round(x/exp(1))

# See also:
#   https://projecteuler.net/problem=183

use 5.010;
use strict;
use warnings;

sub maximum_split {
    my ($n) = @_;

    my $min = 1;
    my $max = $n;

    while ($min < $max) {
        my $mid = ($min + $max) >> 1;

        my $x_prev = ($mid - 1) * (log($n) - log($mid - 1));
        my $x_curr = ($mid + 0) * (log($n) - log($mid + 0));
        my $x_next = ($mid + 1) * (log($n) - log($mid + 1));

        if ($x_prev < $x_curr and $x_curr > $x_next) {
            return $mid;
        }

        if ($x_prev < $x_curr and $x_curr < $x_next) {
            ++$min;
        }
        else {
            --$max;
        }
    }

    return $min;
}

say maximum_split(8);       #=> 3
say maximum_split(11);      #=> 4
say maximum_split(24);      #=> 9
say maximum_split(5040);    #=> 1854
