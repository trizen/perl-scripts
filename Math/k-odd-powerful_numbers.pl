#!/usr/bin/perl

# Author: Trizen
# Date: 11 February 2020
# Edit: 23 February 2024
# https://github.com/trizen

# Fast recursive algorithm for generating all the odd k-powerful numbers <= n.
# A positive integer n is considered k-powerful, if for every prime p that divides n, so does p^k.

# Example:
#   2-powerful = a^2 * b^3,             for a,b >= 1
#   3-powerful = a^3 * b^4 * c^5,       for a,b,c >= 1
#   4-powerful = a^4 * b^5 * c^6 * d^7, for a,b,c,d >= 1

# See also:
#   https://oeis.org/A062739

use 5.036;
use ntheory qw(:all);

sub odd_powerful_numbers ($n, $k = 2) {

    my @odd_powerful;

    sub ($m, $r) {

        if ($r < $k) {
            push @odd_powerful, $m;
            return;
        }

        foreach my $v (1 .. rootint(divint($n, $m), $r)) {

            next if ($v % 2 == 0);

            if ($r > $k) {
                gcd($m, $v) == 1   or next;
                is_square_free($v) or next;
            }

            __SUB__->(mulint($m, powint($v, $r)), $r - 1);
        }
      }
      ->(1, 2 * $k - 1);

    sort { $a <=> $b } @odd_powerful;
}

foreach my $k (1 .. 10) {
    printf("%2d-odd-powerful: %s, ...\n", $k, join(", ", odd_powerful_numbers(powint(10, $k), $k)));
}

__END__
 1-odd-powerful: 1, 3, 5, 7, 9, ...
 2-odd-powerful: 1, 9, 25, 27, 49, 81, ...
 3-odd-powerful: 1, 27, 81, 125, 243, 343, 625, 729, ...
 4-odd-powerful: 1, 81, 243, 625, 729, 2187, 2401, 3125, 6561, ...
 5-odd-powerful: 1, 243, 729, 2187, 3125, 6561, 15625, 16807, 19683, 59049, 78125, ...
 6-odd-powerful: 1, 729, 2187, 6561, 15625, 19683, 59049, 78125, 117649, 177147, 390625, 531441, 823543, ...
 7-odd-powerful: 1, 2187, 6561, 19683, 59049, 78125, 177147, 390625, 531441, 823543, 1594323, 1953125, 4782969, 5764801, 9765625, ...
 8-odd-powerful: 1, 6561, 19683, 59049, 177147, 390625, 531441, 1594323, 1953125, 4782969, 5764801, 9765625, 14348907, 40353607, 43046721, 48828125, ...
 9-odd-powerful: 1, 19683, 59049, 177147, 531441, 1594323, 1953125, 4782969, 9765625, 14348907, 40353607, 43046721, 48828125, 129140163, 244140625, 282475249, 387420489, ...
10-odd-powerful: 1, 59049, 177147, 531441, 1594323, 4782969, 9765625, 14348907, 43046721, 48828125, 129140163, 244140625, 282475249, 387420489, 1162261467, 1220703125, 1977326743, 3486784401, 6103515625, ...
