#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 09 May 2016
# https://github.com/trizen

# Generator of perfect numbers, using the fact that
# the Mth triangular number, where M is a Mersenne
# prime in the form 2^p-1, gives us a perfect number.

# See also:
#   https://en.wikipedia.org/wiki/Perfect_number

use 5.010;
use strict;
use warnings;

use Math::AnyNum;
use ntheory qw(forprimes is_mersenne_prime);

my $one = Math::AnyNum->one;

forprimes {
    if (is_mersenne_prime($_)) {
        my $n = $one << $_;
        say "2^($_-1) * (2^$_-1) = ", $n * ($n - 1) / 2;
    }
} 1, 100;

__END__
2^(2-1) * (2^2-1) = 6
2^(3-1) * (2^3-1) = 28
2^(5-1) * (2^5-1) = 496
2^(7-1) * (2^7-1) = 8128
2^(13-1) * (2^13-1) = 33550336
2^(17-1) * (2^17-1) = 8589869056
2^(19-1) * (2^19-1) = 137438691328
2^(31-1) * (2^31-1) = 2305843008139952128
2^(61-1) * (2^61-1) = 2658455991569831744654692615953842176
2^(89-1) * (2^89-1) = 191561942608236107294793378084303638130997321548169216
