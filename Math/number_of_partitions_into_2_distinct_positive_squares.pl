#!/usr/bin/perl

# Count the number of partitions of n into 2 distinct nonzero squares.

# See also:
#   https://oeis.org/A025441
#   https://mathworld.wolfram.com/SumofSquaresFunction.html
#   https://en.wikipedia.org/wiki/Fermat%27s_theorem_on_sums_of_two_squares

use 5.020;
use warnings;
use experimental qw(signatures);

use ntheory qw(:all);

# Number of solutions to `n = a^2 + b^2, with 0 < a < b.
sub r2_positive_distinct ($n) {

    my $B = 1;

    foreach my $p (factor_exp($n)) {

        my $r = $p->[0] % 4;

        if ($r == 3) {
            $p->[1] % 2 == 0 or return 0;
        }

        if ($r == 1) {
            $B *= $p->[1] + 1;
        }
    }

    return ($B >> 1);
}

foreach my $n(1..100) {
    print(r2_positive_distinct($n), ", ");
}
