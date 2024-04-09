#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 11 February 2020
# https://github.com/trizen

# Fast recursive algorithm for generating all the k-powerful numbers <= n.
# A positive integer n is considered k-powerful, if for every prime p that divides n, so does p^k.

# Example:
#   2-powerful = a^2 * b^3,             for a,b >= 1
#   3-powerful = a^3 * b^4 * c^5,       for a,b,c >= 1
#   4-powerful = a^4 * b^5 * c^6 * d^7, for a,b,c,d >= 1

# OEIS:
#   https://oeis.org/A001694 -- 2-powerful numbers
#   https://oeis.org/A036966 -- 3-powerful numbers
#   https://oeis.org/A036967 -- 4-powerful numbers
#   https://oeis.org/A069492 -- 5-powerful numbers
#   https://oeis.org/A069493 -- 6-powerful numbers

use 5.020;
use warnings;

use ntheory      qw(:all);
use experimental qw(signatures);

sub powerful_numbers ($n, $k = 2) {

    my @powerful;

    sub ($m, $r) {

        if ($r < $k) {
            push @powerful, $m;
            return;
        }

        foreach my $v (1 .. rootint(divint($n, $m), $r)) {

            if ($r > $k) {
                gcd($m, $v) == 1   or next;
                is_square_free($v) or next;
            }

            __SUB__->(mulint($m, powint($v, $r)), $r - 1);
        }

      }
      ->(1, 2 * $k - 1);

    sort { $a <=> $b } @powerful;
}

foreach my $k (1 .. 10) {
    printf("%2d-powerful: %s, ...\n", $k, join(", ", powerful_numbers(5**$k, $k)));
}

__END__
 1-powerful: 1, 2, 3, 4, 5, ...
 2-powerful: 1, 4, 8, 9, 16, 25, ...
 3-powerful: 1, 8, 16, 27, 32, 64, 81, 125, ...
 4-powerful: 1, 16, 32, 64, 81, 128, 243, 256, 512, 625, ...
 5-powerful: 1, 32, 64, 128, 243, 256, 512, 729, 1024, 2048, 2187, 3125, ...
 6-powerful: 1, 64, 128, 256, 512, 729, 1024, 2048, 2187, 4096, 6561, 8192, 15625, ...
 7-powerful: 1, 128, 256, 512, 1024, 2048, 2187, 4096, 6561, 8192, 16384, 19683, 32768, 59049, 65536, 78125, ...
 8-powerful: 1, 256, 512, 1024, 2048, 4096, 6561, 8192, 16384, 19683, 32768, 59049, 65536, 131072, 177147, 262144, 390625, ...
 9-powerful: 1, 512, 1024, 2048, 4096, 8192, 16384, 19683, 32768, 59049, 65536, 131072, 177147, 262144, 524288, 531441, 1048576, 1594323, 1953125, ...
10-powerful: 1, 1024, 2048, 4096, 8192, 16384, 32768, 59049, 65536, 131072, 177147, 262144, 524288, 531441, 1048576, 1594323, 2097152, 4194304, 4782969, 8388608, 9765625, ...
