#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 20 September 2016
# Website: https://github.com/trizen

# A fast function that returns true when a given number is even-perfect. False otherwise.

# See also:
#   https://en.wikipedia.org/wiki/Perfect_number

use 5.010;
use strict;
use warnings;

use Math::BigNum qw(:constant);
use ntheory qw(next_prime is_mersenne_prime);

sub is_even_perfect {
    my ($n) = @_;

    my $p = 2;

    for (; ;) {
        my $mp = (1 << $p) - 1;
        my $np = ($mp * ($mp + 1) / 2);

        $np > $n && return;

        if (is_mersenne_prime($p) and $np == $n) {
            return 1;
        }

        $p = next_prime($p);
    }
}

say is_even_perfect(191561942608236107294793378084303638130997321548169216);    # true
