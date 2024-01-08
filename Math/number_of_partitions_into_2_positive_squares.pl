#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 24 September 2019
# https://github.com/trizen

# Count the number of representations of n as the sum of two non-zero squares, ignoring order and signs (not necesarily distinct).

# See also:
#   https://oeis.org/A025426 -- Number of partitions of n into 2 nonzero squares.
#   https://oeis.org/A000161 -- Number of partitions of n into 2 squares.
#   https://mathworld.wolfram.com/SumofSquaresFunction.html
#   https://en.wikipedia.org/wiki/Fermat%27s_theorem_on_sums_of_two_squares

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(divisors valuation factor_exp vecsum vecprod);

# Number of solutions to `n = a^2 + b^2, with 0 < a <= b.
sub r2_positive($n) {

    my $B  = 1;
    my $a0 = 0;

    if ($n % 2 == 0) {
        $a0 = valuation($n, 2);
        $n >>= $a0;
    }

    foreach my $p (factor_exp($n)) {

        my $r = $p->[0] % 4;

        if ($r == 3) {
            $p->[1] % 2 == 0 or return 0;
        }

        if ($r == 1) {
            $B *= $p->[1] + 1;
        }
    }

    ($B % 2 == 0) ? ($B >> 1) : (($B - (-1)**$a0) >> 1);
}

foreach my $n (1 .. 100) {
    print(r2_positive($n), ", ");
}

__END__
0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 2, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 2, 0, 0, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 2, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1,
