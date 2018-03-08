#!/usr/bin/perl

# Find the smallest polygonal representation for a given number.

# Example:
#  12 = P(3, 5) since 12 is a pentagonal number, but not a square or triangular.

# Based on code by Chai Wah Wu.

# See also:
#   https://oeis.org/A176774

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(:overload isqrt divmod ipolygonal_root polygonal);

sub polygonal_inverse ($n) {
    for (my $k = (isqrt(8 * $n + 1) - 1) >> 1 ; $k >= 2 ; --$k) {

        my ($x, $y) = divmod(
            2 * ($k * ($k - 2) + $n),
                 $k * ($k - 1)
        );

        return $x if $y == 0;
    }
}

foreach my $i (1 .. 31) {

    my $n = 2**$i + 1;
    my $k = polygonal_inverse($n);
    my $d = ipolygonal_root($n, $k);

    say "2^$i + 1 = P($d, $k)";

    die 'error' if $n != polygonal($d, $k);
}

__END__
2^1 + 1 = P(2, 3)
2^2 + 1 = P(2, 5)
2^3 + 1 = P(3, 4)
2^4 + 1 = P(2, 17)
2^5 + 1 = P(3, 12)
2^6 + 1 = P(5, 8)
2^7 + 1 = P(3, 44)
2^8 + 1 = P(2, 257)
2^9 + 1 = P(9, 16)
2^10 + 1 = P(5, 104)
2^11 + 1 = P(3, 684)
2^12 + 1 = P(17, 32)
2^13 + 1 = P(3, 2732)
2^14 + 1 = P(5, 1640)
2^15 + 1 = P(33, 64)
2^16 + 1 = P(2, 65537)
2^17 + 1 = P(3, 43692)
2^18 + 1 = P(65, 128)
2^19 + 1 = P(3, 174764)
2^20 + 1 = P(17, 7712)
2^21 + 1 = P(129, 256)
2^22 + 1 = P(5, 419432)
2^23 + 1 = P(3, 2796204)
2^24 + 1 = P(257, 512)
2^25 + 1 = P(33, 63552)
2^26 + 1 = P(5, 6710888)
2^27 + 1 = P(513, 1024)
2^28 + 1 = P(17, 1973792)
2^29 + 1 = P(3, 178956972)
2^30 + 1 = P(1025, 2048)
2^31 + 1 = P(3, 715827884)
