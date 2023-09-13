#!/usr/bin/perl

# Author: Trizen
# Date: 13 September 2023
# https://github.com/trizen

# Efficient algorithm for finding the greatest common unitary divisor of a list of integers.

use 5.036;
use ntheory qw(:all);

sub gcud (@list) {

    my $g = gcd(@list);

    foreach my $n (@list) {
        next if ($n == 0);
        while (1) {
            my $t = gcd($g, divint($n, $g));
            last if ($t == 1);
            $g = divint($g, $t);
        }
        last if ($g == 1);
    }

    return $g;
}

say gcud();                              #=> 0
say gcud(2);                             #=> 2
say gcud(10,           20);              #=> 5
say gcud(factorial(9), 5040);            #=> 35
say gcud(factorial(9), 5040, 120);       #=> 5
say gcud(factorial(9), 5040, 0, 120);    #=> 5
say gcud(factorial(9), 5040, 1234);      #=> 1
