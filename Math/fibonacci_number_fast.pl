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

    my ($f, $g)         = (0, 1);
    my ($a, $b, $c, $d) = (0, 1, 1, 1);

    foreach my $i (0 .. ilog2($n)||0) {
        ($f, $g)         = ($f*$a + $g*$c, $f*$b + $g*$d) if getbit($n, $i);
        ($a, $b, $c, $d) = ($a*$a + $b*$c, $a*$b + $b*$d, $c*$a + $d*$c, $c*$b + $d*$d);
    }

    return $f;
}

say fibonacci_number(100);       #=> 354224848179261915075
