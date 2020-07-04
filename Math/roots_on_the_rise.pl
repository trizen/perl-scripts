#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 21 February 2018
# https://github.com/trizen

# Solutions to x for:
#    1/x = (k/x)^2 * (k + x^2) - k*x

# See also:
#   https://projecteuler.net/problem=479

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(:overload);
#use Math::GComplex qw(:overload);

sub roots ($k) {

    # Formulas from Wolfram|Alpha
    # http://www.wolframalpha.com/input/?i=1%2Fx+%3D+(k%2Fx)%5E2+*+(k%2Bx%5E2)++-+k*x

#<<<
    my $x1 = (2*$k**6 + 27 * $k**5 - 9*$k**3 + 3 * sqrt(3) * sqrt(4 * $k**11 + 27 * $k**10 -
    18*$k**8 - $k**6 + 4 *$k**3))**(1/3)/(3 * 2**(1/3) * $k) - (2**(1/3) * (3 * $k - $k**4)
    )/(3 * (2* $k**6 + 27 * $k**5 - 9 * $k**3 + 3*sqrt(3) * sqrt(4*$k**11 + 27*$k**10 - 18 *
    $k**8 - $k**6 + 4 *$k**3))**(1/3) *$k) + $k/3;

    my $x2 = -((1 - i * sqrt(3)) * (2 * $k**6 + 27 *$k**5 - 9 * $k**3 + 3 * sqrt(3) * sqrt(4 *
    $k**11 + 27* $k**10 - 18* $k**8 - $k**6 + 4 * $k**3))**(1/3))/(6 * 2**(1/3) * $k) +
    ((1 + i * sqrt(3)) * (3 * $k - $k**4))/(3 * 2**(2/3) * (2 * $k**6 + 27 * $k**5 - 9 *
    $k**3 + 3 * sqrt(3) * sqrt(4 * $k**11 + 27 * $k**10 - 18 * $k**8 - $k**6 + 4 * $k**3)
    )**(1/3) * $k) + $k/3;

    my $x3 = -((1 + i * sqrt(3)) * (2*$k**6 + 27 * $k**5 - 9 * $k**3 + 3 * sqrt(3) * sqrt(4 *
    $k**11 + 27 * $k**10 - 18 * $k**8 - $k**6 + 4 * $k**3))**(1/3))/(6 * 2**(1/3) * $k) +
    ((1 - i * sqrt(3)) * (3 * $k - $k**4))/(3 * 2**(2/3) * (2 *$k**6 + 27 * $k**5 - 9 * $k**3 +
    3 * sqrt(3) * sqrt(4 *$k**11 + 27 * $k**10 - 18 *$k**8 - $k**6 + 4 * $k**3))**(1/3) * $k) + $k/3;
#>>>

    return ($x1, $x2, $x3);
}

sub S ($n) {
    my $sum = 0;

    foreach my $k (1 .. $n) {

        my ($x1, $x2, $x3) = roots($k);

        foreach my $p (1 .. $n) {
            my $t = ($x1 + $x2)**$p * ($x2 + $x3)**$p * ($x3 + $x1)**$p;
            say "$k -> $t";
            $sum += $t;
        }

        say '';
    }

    return $sum;
}

sub S_int ($n) {
    my $sum = 0;
    foreach my $k (1 .. $n - 1) {
        my $p = ($k + 1)**2 - 1;
        $sum += ($p * ((-1)**$n * $p**$n - 1)) / ($p + 1);
    }
    return $sum;
}

say S(4);
say S_int(4);
