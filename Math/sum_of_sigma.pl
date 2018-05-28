#!/usr/bin/perl

# Algorithm with O(sqrt(n)) complexity for computing the sum of the sum of divisors:
#
#   a(n) = Sum_{k=1..n} sigma(k).
#

# Algorithm due to P. L. Patodia (09.01.2008) (see: https://oeis.org/A024916).

use 5.010;
use strict;
use warnings;

sub sum_of_sigma {
    my ($z) = @_;

    my $p = 0;
    my $s = $z * $z;
    my $u = int(sqrt($z));

    foreach my $d (1 .. $u) {

        my $n = int($z / $d) - int($z / ($d + 1));

        if ($n <= 1) {
            $p = $d;
            last;
        }

        $s -= (2 * ($z % $d) + ($n - 1) * $d) * $n / 2;
    }

    $u = (
          $p == 0
          ? int($z / ($u + 1))
          : int($z / $p)
         );

    foreach my $d (2 .. $u) {
        $s -= $z % $d;
    }

    return $s;
}

say sum_of_sigma(64);       #=> 3403
say sum_of_sigma(1234);     #=> 1252881
say sum_of_sigma(10**8);    #=> 8224670422194237

# a(n) = { 1, 4, 8, 15, 21, 33, 41, 56, 69, 87, 99, 127, 141, 165, 189, ... }
say join(', ', map { sum_of_sigma($_) } 1 .. 15);
