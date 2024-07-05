#!/usr/bin/perl

# An efficient formula for computing the n-th decimal digit of a given fraction expression x/y.

# Formula from:
#   https://stackoverflow.com/questions/804934/getting-a-specific-digit-from-a-ratio-expansion-in-any-base-nth-digit-of-x-y

# See also:
#   https://projecteuler.net/problem=820

use 5.036;
use ntheory qw(:all);

sub nth_digit_of_fraction($n, $x, $y, $base = 10) {
    divint($base * powmod($base, $n - 1, $y) * $x, $y) % $base;
}

say vecsum(map { nth_digit_of_fraction(7,   1, $_) } 1 .. 7);      #=> 10
say vecsum(map { nth_digit_of_fraction(100, 1, $_) } 1 .. 100);    #=> 418
