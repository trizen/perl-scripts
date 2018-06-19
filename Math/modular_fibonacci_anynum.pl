#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 19 June 2018
# https://github.com/trizen

# A very efficient algorithm for computing the nth-Fibonacci number (mod m).

use 5.020;
use warnings;
use experimental qw(signatures);
use Math::AnyNum qw(:overload ilog2 getbit);

sub fibonacci_number($n, $m) {

    my ($f, $g)         = (0, 1);
    my ($a, $b, $c, $d) = (0, 1, 1, 1);

    foreach my $i (0 .. ilog2($n)||0) {
        ($f, $g)         = (($f*$a + $g*$c)%$m, ($f*$b + $g*$d)%$m) if getbit($n, $i);
        ($a, $b, $c, $d) = (($a*$a + $b*$c)%$m, ($a*$b + $b*$d)%$m, ($c*$a + $d*$c)%$m, ($c*$b + $d*$d)%$m);
    }

    return $f;
}

# Last 20 digits of the 10^100-th Fibonacci number
say fibonacci_number(10**100, 10**20);       #=> 59183788299560546875
