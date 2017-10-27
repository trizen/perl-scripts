#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 23 October 2017
# https://github.com/trizen

# Counting the number of representations for a given number `n` expressed as the sum of two squares.

# Formula:
#   R(n) = 4 * Prod_{ p^k|n, p = 1 (mod 4) } (k + 1)

# See also:
#   https://oeis.org/A004018
#   https://en.wikipedia.org/wiki/Fermat%27s_theorem_on_sums_of_two_squares

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(divisors valuation factor_exp vecsum vecprod);

sub count_representations_as_two_squares($n) {

    my $count = 4;
    foreach my $p (factor_exp($n)) {

        my $r = $p->[0] % 4;

        if ($r == 3) {
            $p->[1] % 2 == 0 or return 0;
        }

        if ($r == 1) {
            $count *= $p->[1] + 1;
        }
    }

    return $count;
}

foreach my $n (1 .. 30) {
    my $count = count_representations_as_two_squares($n);

    if ($count != 0) {
        say "R($n) = $count";
    }
}

__END__
R(1) = 4
R(2) = 4
R(4) = 4
R(5) = 8
R(8) = 4
R(9) = 4
R(10) = 8
R(13) = 8
R(16) = 4
R(17) = 8
R(18) = 4
R(20) = 8
R(25) = 12
R(26) = 8
R(29) = 8
