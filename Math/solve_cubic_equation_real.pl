#!/usr/bin/perl

# Find a real solution to a cubic equation, using reduction to a depressed cubic, followed by the Cardano formula.

# Dividing ax^3 + bx^2 + cx + d = 0 by `a` and substituting `t - b/(3a)` for x we get the equation:
#   t^3 + pt + q = 0

# This allows us to use the Cardano formula to solve for `t`, which gives us:
#   x = t - b/(3a)

# Example (with x = 79443853):
#    15 x^3 - 22 x^2 + 8 x - 7520940423059310542039581 = 0

# See also:
#   https://en.wikipedia.org/wiki/Cubic_function

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(:overload cbrt);

sub solve_cubic_equation ($a, $b, $c, $d) {

    my $p = (3*$a*$c - $b*$b) / (3*$a*$a);
    my $q = (2 * $b**3 - 9*$a*$b*$c + 27*$a*$a*$d) / (27 * $a**3);

    my $t = (cbrt(-($q/2) + sqrt(($q**2 / 4) + ($p**3 / 27))) +
             cbrt(-($q/2) - sqrt(($q**2 / 4) + ($p**3 / 27))));

    $t - $b/(3*$a);
}

say solve_cubic_equation(15, -22, 8, -7520940423059310542039581);    #=> 79443852.9999999999999999...
