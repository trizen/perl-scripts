#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 10 May 2016
# https://github.com/trizen

# Determine if a given number can be written as the sum of two squares.

# See also:
#   http://wstein.org/edu/Fall2001/124/lectures/lecture21/lecture21/node2.html

use 5.010;
use strict;
use warnings;

use ntheory qw(factor_exp is_prime);

sub is_sum_of_2_squares {
    my ($n) = @_;

    if (is_prime($n)) {
        return 1 if $n == 2;
        return $n % 4 == 1;
    }

    foreach my $p (factor_exp($n)) {
            $p->[0] % 4 == 3
        and $p->[1] % 2 != 0
        and return 0;
    }

    return 1;
}

for my $i (0 .. 50) {
    if (is_sum_of_2_squares($i)) {
        say $i;
    }
}
