#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 31 August 2016
# License: GPLv3
# https://github.com/trizen

# Algorithm from:
#   http://web.math.princeton.edu/mathlab/jr02fall/Periodicity/mariusjp.pdf

# See also:
#   https://projecteuler.net/problem=64

use 5.010;
use strict;
use warnings;

#
## Defined only for irrational square roots.
#

sub period_length {
    my ($n) = @_;

    my $x_0 = int(sqrt($n));
    my $y   = $x_0;
    my $z   = $n - $x_0 * $x_0;

    my $y_0 = $y;
    my $z_0 = $z;

    my $period = 0;

    do {
        $y = int(($x_0 + $y) / $z) * $z - $y;
        $z = int(($n - $y * $y) / $z);
        ++$period;
    } until (($y == $y_0) && ($z == $z_0));

    $period;
}

for my $i (1 .. 20) {
    int(sqrt($i))**2 == $i and next;
    say "P($i) = ", period_length($i);
}

__END__
P(2) = 1
P(3) = 2
P(5) = 1
P(6) = 2
P(7) = 4
P(8) = 2
P(10) = 1
P(11) = 2
P(12) = 2
P(13) = 5
P(14) = 4
P(15) = 2
P(17) = 1
P(18) = 2
P(19) = 6
P(20) = 2
