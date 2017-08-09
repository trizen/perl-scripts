#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 09 August 2017
# https://github.com/trizen

# Integer factorization concept, based on the quadratic formula.

# Given an integer `z` to be factored, we're considering (x, y) integers such as:
#
#    y^2 + 4*x*z = k^2
#
# for some integer `k`.
#

# The solutions (m, n) to `x^2 + y - z = 0`, can be used to factor `z`, as:
#
#   z = abs(numerator(m)) * abs(numerator(n))
#

# This is just a concept and needs to be optimized to actually use it in practice.

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(:overload isqrt is_square);

sub integer_quadratic_formula {
    my ($x, $y, $z) = @_;

    is_square($y**2 - 4 * $x * $z) || return ();

    (
        ((-$y + isqrt($y**2 - 4 * $x * $z)) / (2 * $x)),
        ((-$y - isqrt($y**2 - 4 * $x * $z)) / (2 * $x)),
    );
}

my $t = 4561 * 73849;

OUTER: foreach my $x (1 .. 500) {
    foreach my $y (1 .. 500) {

        my ($x1, $x2) = integer_quadratic_formula($x, $y, -$t);

        if (defined($x1) and $x * $x1**2 + $y * $x1 - $t == 0) {

            # (405, 196) -> (73849/81, -4561/5) -> (73849 * 4561)
            say "($x, $y) -> ($x1, $x2) -> (",
                $x1->numerator->abs, " * ",
                $x2->numerator->abs,
            ")";

            last OUTER;
        }
    }
}
