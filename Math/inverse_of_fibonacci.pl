#!/usr/bin/perl

# Find the position of a Fibonacci number in the Fibonacci sequence.

# See also:
#   https://en.wikipedia.org/wiki/Fibonacci_number#Recognizing_Fibonacci_numbers

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(:overload fibonacci is_square isqrt phi);

sub fibonacci_inverse ($n) {

    my $m = 5 * $n * $n;

    if (is_square($m - 4)) {
        $m = isqrt($m - 4);
    }
    elsif (is_square($m + 4)) {
        $m = isqrt($m + 4);
    }
    else {
        return -1;    # not a Fibonacci number
    }

    log(($n * sqrt(5) + $m) / 2) / log(phi);
}

say fibonacci_inverse(fibonacci(100));    #=> 100
say fibonacci_inverse(fibonacci(101));    #=> 101
