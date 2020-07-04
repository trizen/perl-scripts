#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 09 August 2017
# https://github.com/trizen

# Representation of quadratic polynomials in terms of their zeros.

# Let:
#    P(x) = a*x^2 + b*x + c

# Let (m, n) be the solutions to P(x) = 0

# Then:
#   P(x) = c * (1 - x/m) * (1 - x/n)

use 5.010;
use strict;
use warnings;

use Math::Bacovia qw(:all);
use Math::AnyNum qw(isqrt);

sub integer_quadratic_formula {
    my ($x, $y, $z) = @_;
    (
        Fraction((-$y + isqrt($y**2 - 4 * $x * $z)), (2 * $x)),
        Fraction((-$y - isqrt($y**2 - 4 * $x * $z)), (2 * $x)),
    );
}

my @poly = (
    [  3, -15,   -42],
    [ 20, -97, -2119],
    [-43,  29, 14972],
);

my $x = Symbol('x');

foreach my $t (@poly) {
    my ($x1, $x2) = integer_quadratic_formula(@$t);

    my $expr = $t->[0] * $x**2 + $t->[1] * $x + $t->[2];

    my $f1 = (1 - $x / $x1);
    my $f2 = (1 - $x / $x2);

    printf("%s = %s * %s * %s\n",
        $expr->pretty,
        $f1->simple->pretty,
        $f2->simple->pretty,
        $t->[2],
    );
}

__END__

((3 * x^2) + (-15 * x) + -42) = (1 - (x/7)) * (1 - (x/-2)) * -42
((20 * x^2) + (-97 * x) + -2119) = (1 - (x/13)) * (1 - (x/(-326/40))) * -2119
((-43 * x^2) + (29 * x) + 14972) = (1 - (x/(-788/43))) * (1 - (x/19)) * 14972
