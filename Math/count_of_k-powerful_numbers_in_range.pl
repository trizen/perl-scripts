#!/usr/bin/perl

# Author: Trizen
# Date: 28 February 2021
# Edit: 11 April 2024
# https://github.com/trizen

# Fast recursive algorithm for counting the number of k-powerful numbers in a given range [A,B].
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

use 5.036;
use ntheory qw(:all);

sub divceil ($x, $y) {    # ceil(x/y)
    (($x % $y == 0) ? 0 : 1) + divint($x, $y);
}

sub powerful_count_in_range ($A, $B, $k = 2) {

    return 0 if ($A > $B);

    my $count = 0;

    sub ($m, $r) {

        my $from = 1;
        my $upto = rootint(divint($B, $m), $r);

        if ($r <= $k) {

            if ($A > $m) {

                # Optimization by Dana Jacobsen (from Math::Prime::Util::PP)
                my $l = divceil($A, $m);
                if (($l >> $r) == 0) {
                    $from = 2;
                }
                else {
                    $from = rootint($l, $r);
                    $from++ if (powint($from, $r) != $l);
                }
            }

            $count += $upto - $from + 1;
            return;
        }

        foreach my $v ($from .. $upto) {
            gcd($m, $v) == 1   or next;
            is_square_free($v) or next;
            __SUB__->(mulint($m, powint($v, $r)), $r - 1);
        }
      }
      ->(1, 2 * $k - 1);

    return $count;
}

require Math::Sidef;

foreach my $k (2 .. 10) {

    my $lo = int rand powint(10, $k - 1);
    my $hi = int rand powint(10, $k);

    my $c1 = powerful_count_in_range($lo, $hi, $k);
    my $c2 = Math::Sidef::powerful_count($k, $lo, $hi);

    $c1 eq $c2 or die "Error for [$lo, $hi] -- ($c1 != $c2)\n";

    printf("Number of %2d-powerful in range 10^j .. 10^(j+1): {%s}\n",
           $k, join(", ", map { powerful_count_in_range(powint(10, $_), powint(10, $_ + 1), $k) } 0 .. $k + 7));
}

__END__
Number of  2-powerful in range 10^j .. 10^(j+1): {4, 10, 41, 132, 435, 1409, 4527, 14492, 46188, 146892}
Number of  3-powerful in range 10^j .. 10^(j+1): {2, 5, 13, 32, 79, 179, 407, 933, 2077, 4628, 10242}
Number of  4-powerful in range 10^j .. 10^(j+1): {1, 4, 6, 14, 33, 61, 119, 230, 443, 836, 1572, 2925}
Number of  5-powerful in range 10^j .. 10^(j+1): {1, 2, 5, 8, 16, 32, 55, 95, 165, 285, 495, 848, 1403}
Number of  6-powerful in range 10^j .. 10^(j+1): {1, 1, 4, 6, 9, 17, 33, 52, 86, 130, 217, 350, 552, 876}
Number of  7-powerful in range 10^j .. 10^(j+1): {1, 0, 3, 6, 6, 10, 20, 32, 53, 76, 115, 178, 267, 412, 628}
Number of  8-powerful in range 10^j .. 10^(j+1): {1, 0, 2, 5, 5, 6, 13, 20, 34, 51, 77, 105, 153, 223, 328, 481}
Number of  9-powerful in range 10^j .. 10^(j+1): {1, 0, 1, 4, 5, 5, 8, 14, 21, 36, 52, 73, 101, 137, 192, 276, 390}
Number of 10-powerful in range 10^j .. 10^(j+1): {1, 0, 0, 4, 4, 5, 7, 7, 15, 25, 37, 52, 73, 96, 126, 175, 238, 335}
