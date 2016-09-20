#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 20 September 2016
# Website: https://github.com/trizen

# A very fast function that returns true when a given number is even-perfect. False otherwise.

# See also:
#   https://en.wikipedia.org/wiki/Perfect_number

use 5.010;
use strict;
use warnings;

use Math::BigNum qw(:constant);
use ntheory qw(is_mersenne_prime valuation hammingweight is_power sqrtint);

sub is_even_perfect {
    my ($n) = @_;

    $n % 2 == 0 || return 0;

    my $square = 8 * $n + 1;
    is_power($square, 2) || return 0;

    my $k = (sqrtint($square) + 1) / 2;

    #($k & ($k - 1)) == 0 && is_mersenne_prime(valuation($k, 2)) ? 1 : 0;
    hammingweight($k) == 1 && is_mersenne_prime(valuation($k, 2)) ? 1 : 0;
}

say is_even_perfect(191561942608236107294793378084303638130997321548169216);                           # true
say is_even_perfect(191561942608236107294793378084303638130997321548169214);                           # false
say is_even_perfect(191561942608236107294793378084303638130997321548169218);                           # false
say is_even_perfect(14474011154664524427946373126085988481573677491474835889066354349131199152128);    # true
