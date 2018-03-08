#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 08 March 2018
# https://github.com/trizen

# Find all the possible polygonal representations P(a,b) for a given number `n`.

# Example:
#  235 = P(5, 25) = P(235, 2) = P(10, 7)

# See also:
#   https://oeis.org/A176774

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use ntheory qw(divisors);
use Math::AnyNum qw(:overload polygonal);

sub polygonal_representations ($n) {

    my @divisors = divisors($n);

    shift @divisors;    # skip d=1

    push @divisors, map { 2 * $_ } @divisors;

    my @representations;

    foreach my $d (@divisors) {

        my $t = $d - 1;
        my $k = 2 * ($n / $d + $d - 2);

        if ($k % $t == 0) {
            push @representations, [$d, $k / $t];
        }
    }

    return @representations;
}

foreach my $i (1 .. 31) {

    my $n = 2**$i + 1;
    my @P = polygonal_representations($n);

    # Display the solutions
    say "2^$i + 1 = ", join(' = ', map { "P($_->[0], $_->[1])" } @P);

    # Verify the solutions
    die 'error' if grep { $_ != $n } map { polygonal($_->[0], $_->[1]) } @P;
}

__END__
2^1 + 1 = P(3, 2)
2^2 + 1 = P(5, 2)
2^3 + 1 = P(3, 4) = P(9, 2)
2^4 + 1 = P(17, 2)
2^5 + 1 = P(3, 12) = P(33, 2)
2^6 + 1 = P(5, 8) = P(65, 2)
2^7 + 1 = P(3, 44) = P(129, 2)
2^8 + 1 = P(257, 2)
2^9 + 1 = P(3, 172) = P(9, 16) = P(513, 2)
2^10 + 1 = P(5, 104) = P(1025, 2)
2^11 + 1 = P(3, 684) = P(2049, 2)
2^12 + 1 = P(17, 32) = P(4097, 2)
2^13 + 1 = P(3, 2732) = P(8193, 2)
2^14 + 1 = P(5, 1640) = P(16385, 2)
2^15 + 1 = P(3, 10924) = P(9, 912) = P(33, 64) = P(32769, 2)
2^16 + 1 = P(65537, 2)
2^17 + 1 = P(3, 43692) = P(131073, 2)
2^18 + 1 = P(5, 26216) = P(65, 128) = P(262145, 2)
2^19 + 1 = P(3, 174764) = P(524289, 2)
2^20 + 1 = P(17, 7712) = P(1048577, 2)
2^21 + 1 = P(3, 699052) = P(9, 58256) = P(129, 256) = P(2097153, 2)
2^22 + 1 = P(5, 419432) = P(4194305, 2)
2^23 + 1 = P(3, 2796204) = P(8388609, 2)
2^24 + 1 = P(257, 512) = P(16777217, 2)
2^25 + 1 = P(3, 11184812) = P(33, 63552) = P(33554433, 2)
2^26 + 1 = P(5, 6710888) = P(67108865, 2)
2^27 + 1 = P(3, 44739244) = P(9, 3728272) = P(513, 1024) = P(134217729, 2)
2^28 + 1 = P(17, 1973792) = P(268435457, 2)
2^29 + 1 = P(3, 178956972) = P(536870913, 2)
2^30 + 1 = P(5, 107374184) = P(65, 516224) = P(1025, 2048) = P(1073741825, 2)
2^31 + 1 = P(3, 715827884) = P(2147483649, 2)
