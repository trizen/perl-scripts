#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 19 June 2018
# https://github.com/trizen

# A very efficient algorithm for computing the nth-Fibonacci number.

use 5.020;
use warnings;
use experimental qw(signatures);
use Math::AnyNum qw(:overload ilog2 getbit);

sub fibonacci_number($n) {

    my ($f, $g) = (0, 1);
    my ($a, $b) = (0, 1);

    foreach my $k (0 .. ilog2($n)||0) {
        ($f, $g) = ($f*$a + $g*$b, $f*$b + $g*($a+$b)) if getbit($n, $k);
        ($a, $b) = ($a*$a + $b*$b, $a*$b + $b*($a+$b));
    }

    return $f;
}

say fibonacci_number(100);                              #=> 354224848179261915075
say join(' ', map { fibonacci_number($_) } 0 .. 15);    #=> 0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610
