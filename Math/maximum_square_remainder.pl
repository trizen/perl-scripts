#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 31 August 2016
# https://github.com/trizen

# Find the maximum remainder of (a-1)^n + (a+1)^n when divided by a^2, for any positive integer n.

# Example with a=7 and n=3:
#
#      (7-1)^3 + (7+1)^3 = 42  (mod 7^2)
#
# In turns out that 42 is the maximum remainder when a=7.

# See also:
#   http://oeis.org/A159469
#   https://projecteuler.net/problem=120

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

sub max_square_remainder($n) {
    $n * ($n - (2 - ($n % 2)));
}

foreach my $n (3 .. 20) {
    say "R($n) = ", max_square_remainder($n);
}

__END__
R(3) = 6
R(4) = 8
R(5) = 20
R(6) = 24
R(7) = 42
R(8) = 48
R(9) = 72
R(10) = 80
R(11) = 110
R(12) = 120
R(13) = 156
R(14) = 168
R(15) = 210
R(16) = 224
R(17) = 272
R(18) = 288
R(19) = 342
R(20) = 360
