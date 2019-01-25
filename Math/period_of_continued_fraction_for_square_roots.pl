#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 31 August 2016
# License: GPLv3
# https://github.com/trizen

# Compute the period length of the continued fraction for square root of a given number.

# Algorithm from:
#   http://web.math.princeton.edu/mathlab/jr02fall/Periodicity/mariusjp.pdf

# OEIS sequences:
#   https://oeis.org/A003285 -- Period of continued fraction for square root of n (or 0 if n is a square).
#   https://oeis.org/A059927 -- Period length of the continued fraction for sqrt(2^(2n+1)).
#   https://oeis.org/A064932 -- Period length of the continued fraction for sqrt(3^(2n+1)).
#   https://oeis.org/A067280 -- Terms in continued fraction for sqrt(n), excl. 2nd and higher periods.

# See also:
#   https://en.wikipedia.org/wiki/Continued_fraction
#   http://mathworld.wolfram.com/PeriodicContinuedFraction.html

# This program was used in computing the a(15)-a(19) terms of the OEIS sequence A064932.
#   A064932(15) = 15924930
#   A064932(16) = 47779238
#   A064932(17) = 143322850
#   A064932(18) = 429998586
#   A064932(19) = 1289970842

use 5.010;
use strict;
use warnings;

use ntheory qw(is_square sqrtint powint divint);

sub period_length {
    my ($n) = @_;

    my $x = sqrtint($n);
    my $y = $x;
    my $z = 1;

    return 0 if is_square($n);

    my $period = 0;

    do {
        $y = divint(($x + $y),      $z) * $z - $y;
        $z = divint(($n - $y * $y), $z);
        ++$period;
    } until ($z == 1);

    return $period;
}

for my $n (1 .. 14) {
    print "A064932($n) = ", period_length(powint(3, 2 * $n + 1)), "\n";
}

__END__
A064932(1) = 2
A064932(2) = 10
A064932(3) = 30
A064932(4) = 98
A064932(5) = 270
A064932(6) = 818
A064932(7) = 2382
A064932(8) = 7282
A064932(9) = 21818
A064932(10) = 65650
A064932(11) = 196406
A064932(12) = 589982
A064932(13) = 1768938
A064932(14) = 5309294
