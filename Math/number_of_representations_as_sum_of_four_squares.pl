#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 23 October 2017
# https://github.com/trizen

# Counting the number of representations for a given number `n` expressed as the sum of four squares.

# Formula:
#   R(n) = 8 * Sum_{d | n, d != 0 (mod 4)} d

# See also:
#   https://oeis.org/A000118
#   https://en.wikipedia.org/wiki/Lagrange's_four-square_theorem

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(is_prime divisor_sum);

sub count_representations_as_four_squares($n) {

    my $count = 8 * divisor_sum($n);

    if ($n % 4 == 0) {
        $count -= 32 * divisor_sum($n >> 2);
    }

    return $count;
}

foreach my $n (1 .. 20) {
    say "R($n) = ", count_representations_as_four_squares($n);
}

__END__
R(1) = 8
R(2) = 24
R(3) = 32
R(4) = 24
R(5) = 48
R(6) = 96
R(7) = 64
R(8) = 24
R(9) = 104
R(10) = 144
R(11) = 96
R(12) = 96
R(13) = 112
R(14) = 192
R(15) = 192
R(16) = 24
R(17) = 144
R(18) = 312
R(19) = 160
R(20) = 144
