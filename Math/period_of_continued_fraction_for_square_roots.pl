#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 31 August 2016
# License: GPLv3
# https://github.com/trizen

# Algorithm from:
#   https://web.math.princeton.edu/mathlab/jr02fall/Periodicity/mariusjp.pdf

# See also:
#   https://oeis.org/A003285
#   https://oeis.org/A067280
#   https://projecteuler.net/problem=64
#   https://en.wikipedia.org/wiki/Continued_fraction
#   https://mathworld.wolfram.com/PeriodicContinuedFraction.html

use 5.010;
use strict;
use warnings;

use ntheory qw(is_square sqrtint);

sub period_length {
    my ($n) = @_;

    my $x = sqrtint($n);
    my $y = $x;
    my $z = 1;

    return 0 if is_square($n);

    my $period = 0;

    do {
        $y = int(($x + $y) / $z) * $z - $y;
        $z = int(($n - $y * $y) / $z);
        ++$period;
    } until ($z == 1);

    return $period;
}

for my $i (1 .. 20) {
    say "P($i) = ", period_length($i);
}

__END__
P(1) = 0
P(2) = 1
P(3) = 2
P(4) = 0
P(5) = 1
P(6) = 2
P(7) = 4
P(8) = 2
P(9) = 0
P(10) = 1
P(11) = 2
P(12) = 2
P(13) = 5
P(14) = 4
P(15) = 2
P(16) = 0
P(17) = 1
P(18) = 2
P(19) = 6
P(20) = 2
