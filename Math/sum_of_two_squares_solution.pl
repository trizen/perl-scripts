#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 24 October 2017
# https://github.com/trizen

# Algorithm for finding a solution to the equation a^2 + b^2 = n,
# for any given positive integer `n` for which such a solution exists.

# This algorithm is efficient when the factorization of `n` is known.

# See also:
#   https://oeis.org/A001481

use 5.020;
use strict;
use warnings;

use ntheory qw(sqrtmod factor_exp);
use experimental qw(signatures);

sub sum_of_two_squares_solution ($n) {

    $n == 0 and return (0, 0);

    my $prod1 = 1;
    my $prod2 = 1;

    foreach my $f (factor_exp($n)) {
        if ($f->[0] % 4 == 3) {            # p = 3 (mod 4)
            $f->[1] % 2 == 0 or return;    # power must be even
            $prod2 *= $f->[0]**($f->[1] >> 1);
        }
        elsif ($f->[0] == 2) {             # p = 2
            if ($f->[1] % 2 == 0) {        # power is even
                $prod2 *= $f->[0]**($f->[1] >> 1);
            }
            else {                         # power is odd
                $prod1 *= $f->[0];
                $prod2 *= $f->[0]**(($f->[1] - 1) >> 1);
            }
        }
        else {                             # p = 1 (mod 4)
            $prod1 *= $f->[0]**$f->[1];
        }
    }

    $prod1 == 1 and return ($prod2, 0);
    $prod1 == 2 and return ($prod2, $prod2);

    my $s = sqrtmod($prod1 - 1, $prod1) || return;
    my $q = $prod1;

    while ($s * $s > $prod1) {
        ($s, $q) = ($q % $s, $s);
    }

    return ($prod2 * $s, $prod2 * ($q % $s));
}

foreach my $n (0 .. 1e5) {
    my ($x, $y, $z) = sum_of_two_squares_solution($n);

    if (defined($x) and defined($y)) {
        say "f($n) = $x^2 + $y^2";

        if ($n != $x**2 + $y**2) {
            warn "error for $n\n";
        }
    }
}

__END__
f(999909) = 735^2 + 678^2
f(999914) = 745^2 + 667^2
f(999917) = 994^2 + 109^2
f(999937) = 996^2 + 89^2
f(999938) = 997^2 + 77^2
f(999940) = 718^2 + 696^2
f(999941) = 895^2 + 446^2
f(999944) = 770^2 + 638^2
f(999946) = 811^2 + 585^2
f(999949) = 970^2 + 243^2
f(999952) = 896^2 + 444^2
f(999953) = 823^2 + 568^2
f(999954) = 927^2 + 375^2
f(999956) = 866^2 + 500^2
f(999961) = 765^2 + 644^2
f(999962) = 841^2 + 541^2
f(999968) = 892^2 + 452^2
f(999970) = 779^2 + 627^2
f(999973) = 753^2 + 658^2
f(999981) = 990^2 + 141^2
f(999986) = 931^2 + 365^2
f(999997) = 981^2 + 194^2
f(1000000) = 936^2 + 352^2
