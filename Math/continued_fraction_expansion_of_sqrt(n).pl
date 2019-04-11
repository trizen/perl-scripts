#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 11 April 2019
# https://github.com/trizen

# Compute the simple continued fraction expansion for the square root of a given number.

# Algorithm from:
#   http://web.math.princeton.edu/mathlab/jr02fall/Periodicity/mariusjp.pdf

# See also:
#   https://en.wikipedia.org/wiki/Continued_fraction
#   http://mathworld.wolfram.com/PeriodicContinuedFraction.html

use 5.020;
use strict;
use warnings;

use Math::AnyNum qw(is_square isqrt idiv);
use experimental qw(signatures);

sub cfrac_sqrt ($n) {

    my $x = isqrt($n);
    my $y = $x;
    my $z = 1;
    my $r = 2 * $x;

    return ($x) if is_square($n);

    my @cfrac = ($x);

    do {
        $y = $r * $z - $y;
        $z = ($n - $y*$y) / $z;
        $r = idiv(($x + $y), $z);

        push @cfrac, $r;
    } until ($z == 1);

    return @cfrac;
}

foreach my $n (1 .. 20) {
    say "sqrt($n) = [", join(', ', cfrac_sqrt($n)), "]";
}

__END__
sqrt(1) = [1]
sqrt(2) = [1, 2]
sqrt(3) = [1, 1, 2]
sqrt(4) = [2]
sqrt(5) = [2, 4]
sqrt(6) = [2, 2, 4]
sqrt(7) = [2, 1, 1, 1, 4]
sqrt(8) = [2, 1, 4]
sqrt(9) = [3]
sqrt(10) = [3, 6]
sqrt(11) = [3, 3, 6]
sqrt(12) = [3, 2, 6]
sqrt(13) = [3, 1, 1, 1, 1, 6]
sqrt(14) = [3, 1, 2, 1, 6]
sqrt(15) = [3, 1, 6]
sqrt(16) = [4]
sqrt(17) = [4, 8]
sqrt(18) = [4, 4, 8]
sqrt(19) = [4, 2, 1, 3, 1, 2, 8]
sqrt(20) = [4, 2, 8]
