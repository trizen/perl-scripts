#!/usr/bin/perl

# Author: Trizen
# Date: 28 February 2021
# Edit: 23 February 2024
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
use ntheory      qw(:all);
use Math::AnyNum qw(faulhaber_sum);

sub divceil ($x, $y) {    # ceil(x/y)
    (($x % $y == 0) ? 0 : 1) + divint($x, $y);
}

sub powerful_sum_in_range ($A, $B, $k = 2) {

    return 0 if ($A > $B);

    my $sum = 0;

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

            return if ($from > $upto);
            $sum += $m * (faulhaber_sum($upto, $r) - faulhaber_sum($from - 1, $r));
            return;
        }

        foreach my $v ($from .. $upto) {
            gcd($m, $v) == 1   or next;
            is_square_free($v) or next;
            __SUB__->(mulint($m, powint($v, $r)), $r - 1);
        }
      }
      ->(1, 2 * $k - 1);

    return $sum;
}

require Math::Sidef;

foreach my $k (2 .. 10) {

    my $lo = int rand powint(10, $k - 1);
    my $hi = int rand powint(10, $k);

    my $c1 = powerful_sum_in_range($lo, $hi, $k);
    my $c2 = Math::Sidef::powerful_sum($k, $lo, $hi);

    $c1 eq $c2 or die "Error for [$lo, $hi] -- ($c1 != $c2)\n";

    printf("Sum of %2d-powerful in range 10^j .. 10^(j+1): {%s}\n",
           $k, join(", ", map { powerful_sum_in_range(powint(10, $_), powint(10, $_ + 1), $k) } 0 .. $k + 7));
}

__END__
Sum of  2-powerful in range 10^j .. 10^(j+1): {22, 502, 19545, 628164, 20656197, 668961441, 21437300251, 685328369991, 21824118507902, 693905863243612}
Sum of  3-powerful in range 10^j .. 10^(j+1): {9, 220, 6121, 136410, 3529846, 80934268, 1811337810, 41811161255, 929876351992, 20679545550210, 457363233598112}
Sum of  4-powerful in range 10^j .. 10^(j+1): {1, 193, 2493, 60370, 1440893, 26780053, 516891583, 9990376094, 193432085418, 3626702483663, 68456092587576, 1272728145913757}
Sum of  5-powerful in range 10^j .. 10^(j+1): {1, 96, 1868, 35009, 746121, 14039356, 230448956, 4041417437, 70765409052, 1214243920880, 21187881376824, 365947199216587, 6015063920839580}
Sum of  6-powerful in range 10^j .. 10^(j+1): {1, 64, 1625, 24108, 427138, 7503765, 142877197, 2128546916, 37085174023, 547117264876, 9207435088386, 149796088225544, 2342746880282546, 36741577488049351}
Sum of  7-powerful in range 10^j .. 10^(j+1): {1, 0, 896, 24108, 271545, 4519876, 93259499, 1349452792, 22365106723, 310086289407, 4736025082478, 73612282993023, 1102078225069540, 16970183647609915, 262120890688576034}
Sum of  8-powerful in range 10^j .. 10^(j+1): {1, 0, 768, 21921, 193420, 2016717, 56385643, 851106512, 14014480848, 205584890161, 3186168004038, 43689401756765, 641512327279056, 9291932808199869, 136568208040185109, 2007778182656517551}
Sum of  9-powerful in range 10^j .. 10^(j+1): {1, 0, 512, 15360, 193420, 1626092, 33824682, 596581840, 8827764302, 147389799084, 2165109680321, 29580803725639, 409447338905006, 5697214477371426, 78740331560394730, 1144313243099576141, 15965319118886658764}
Sum of 10-powerful in range 10^j .. 10^(j+1): {1, 0, 0, 15360, 173737, 1626092, 31871557, 284130441, 5610671182, 106206715265, 1591481398917, 21833753103320, 298489744207556, 3892787043427942, 50393901956156445, 725082729912431153, 9766175708618550818, 140084863743264508627}
