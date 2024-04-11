#!/usr/bin/perl

# Author: Trizen
# Date: 28 February 2021
# Edit: 11 April 2024
# https://github.com/trizen

# Fast recursive algorithm for generating all the k-powerful numbers in a given range [A,B].
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

use 5.036;
use ntheory qw(:all);

sub divceil ($x, $y) {    # ceil(x/y)
    (($x % $y == 0) ? 0 : 1) + divint($x, $y);
}

sub powerful_numbers ($A, $B, $k = 2) {

    my @powerful;

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

            foreach my $j ($from .. $upto) {
                push @powerful, mulint($m, powint($j, $r));
            }

            return;
        }

        foreach my $v ($from .. $upto) {

            gcd($m, $v) == 1   or next;
            is_square_free($v) or next;

            __SUB__->(mulint($m, powint($v, $r)), $r - 1);
        }
      }
      ->(1, 2 * $k - 1);

    sort { $a <=> $b } @powerful;
}

require Math::Sidef;

my $A = int rand 1e5;
my $B = int rand 1e7;

foreach my $k (2 .. 5) {
    say "Testing: k = $k";
    my @a1 = powerful_numbers($A, $B, $k);
    my @a2 = Math::Sidef::powerful($k, $A, $B);
    my @a3 = grep { $_ >= $A } powerful_numbers(1, $B, $k);
    "@a1" eq "@a2" or die "error for: powerful_numbers($A, $B, $k)";
    "@a1" eq "@a3" or die "error for: powerful_numbers($A, $B, $k)";
}

say join(', ', powerful_numbers(1e6 - 1e4, 1e6, 2));    #=> 990025, 990125, 990584, 991232, 992016, 994009, 995328, 996004, 996872, 998001, 998784, 1000000
