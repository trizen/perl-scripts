#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 11 February 2020
# https://github.com/trizen

# Fast recursive algorithm for counting the number of k-powerful numbers <= n.
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

# See also:
#   https://oeis.org/A118896 -- Number of powerful numbers <= 10^n.

use 5.020;
use warnings;

use ntheory      qw(rootint divint gcd is_square_free mulint powint);
use experimental qw(signatures);

sub powerful_count ($n, $k = 2) {

    my $count = 0;

    sub ($m, $r) {

        if ($r <= $k) {
            $count += rootint(divint($n, $m), $r);
            return;
        }

        foreach my $v (1 .. rootint(divint($n, $m), $r)) {

            gcd($m, $v) == 1   or next;
            is_square_free($v) or next;

            __SUB__->(mulint($m, powint($v, $r)), $r - 1);
        }
      }
      ->(1, 2 * $k - 1);

    return $count;
}

foreach my $k (2 .. 10) {
    printf("Number of %2d-powerful <= 10^j: {%s}\n", $k, join(', ', map { powerful_count(powint(10, $_), $k) } 0 .. ($k + 15)));
}

__END__
Number of  2-powerful <= 10^j: {1, 4, 14, 54, 185, 619, 2027, 6553, 21044, 67231, 214122, 680330, 2158391, 6840384, 21663503, 68575557, 217004842, 686552743}
Number of  3-powerful <= 10^j: {1, 2, 7, 20, 51, 129, 307, 713, 1645, 3721, 8348, 18589, 41136, 90619, 198767, 434572, 947753, 2062437, 4480253}
Number of  4-powerful <= 10^j: {1, 1, 5, 11, 25, 57, 117, 235, 464, 906, 1741, 3312, 6236, 11654, 21661, 40049, 73699, 135059, 246653, 449088}
Number of  5-powerful <= 10^j: {1, 1, 3, 8, 16, 32, 63, 117, 211, 375, 659, 1153, 2000, 3402, 5770, 9713, 16266, 27106, 45003, 74410, 122594}
Number of  6-powerful <= 10^j: {1, 1, 2, 6, 12, 21, 38, 70, 121, 206, 335, 551, 900, 1451, 2326, 3706, 5853, 9167, 14316, 22261, 34471, 53222}
Number of  7-powerful <= 10^j: {1, 1, 1, 4, 10, 16, 26, 46, 77, 129, 204, 318, 495, 761, 1172, 1799, 2740, 4128, 6200, 9224, 13671, 20205, 29764}
Number of  8-powerful <= 10^j: {1, 1, 1, 3, 8, 13, 19, 32, 52, 85, 135, 211, 315, 467, 689, 1016, 1496, 2191, 3214, 4653, 6705, 9610, 13694, 19460}
Number of  9-powerful <= 10^j: {1, 1, 1, 2, 6, 11, 16, 24, 38, 59, 94, 145, 217, 317, 453, 644, 919, 1308, 1868, 2651, 3745, 5259, 7337, 10203, 14090}
Number of 10-powerful <= 10^j: {1, 1, 1, 1, 5, 9, 14, 21, 28, 43, 68, 104, 155, 227, 322, 447, 621, 858, 1192, 1651, 2279, 3152, 4334, 5928, 8075, 10943}
