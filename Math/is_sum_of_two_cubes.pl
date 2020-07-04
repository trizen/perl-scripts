#!/usr/bin/perl

# Determine if a given integer can be represented as a sum of two nonnegative cubes.

# See also:
#   https://oeis.org/A004999 -- Sums of two nonnegative cubes.
#   https://cs.uwaterloo.ca/journals/JIS/VOL6/Broughan/broughan25.pdf

use 5.020;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub is_sum_of_two_cubes($n) {

    my $L = rootint($n-1, 3) + 1;
    my $U = rootint(4*$n, 3);

    foreach my $m (divisors($n)) {
        if ($L <= $m and $m <= $U) {
            my $l = $m*$m - $n/$m;
            $l % 3 == 0 or next;
            $l /= 3;
            is_square($m*$m - 4*$l) && return 1;
        }
    }

    return;
}

foreach my $n (1 .. 1000) {
    if (is_sum_of_two_cubes($n)) {
        print($n, ", ");
    }
}
