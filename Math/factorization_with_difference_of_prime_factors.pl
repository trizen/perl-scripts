#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 09 August 2017
# https://github.com/trizen

# Theorem:
#   If the absolute difference between the prime factors of a
#   semiprime `n` is known, then `n` can be factored in polynomial time.

# For example:
#   n = 97 * 43
#   n = 4171
#
#   d = 97 - 43
#   d = 54

# Then the factors of `n` are:
#   43 = abs((-54 + sqrt(54^2 + 4*4171)) / 2)
#   97 = abs((-54 - sqrt(54^2 + 4*4171)) / 2)

# In general:
#   n = p * q
#   d = abs(p - q)

# From which `n` can be factored as:
#   n = abs((-d + sqrt(d^2 + 4*n)) / 2) *
#       abs((-d - sqrt(d^2 + 4*n)) / 2)
#

# Based on the following quadratic equation:
#   x^2 + (a - b)*x - a*b = 0
#
# which has the solutions:
#   x₁ = -a
#   x₂ = +b

use 5.010;
use strict;
use warnings;

use ntheory qw(random_nbit_prime);
use Math::AnyNum qw(:overload isqrt);

my $p = Math::AnyNum->new(random_nbit_prime(100));
my $q = Math::AnyNum->new(random_nbit_prime(100));

my $d = abs($p - $q);
my $n = $p * $q;

say "n = $p * $q";
say "d = $d";

sub integer_quadratic_formula {
    my ($x, $y, $z) = @_;

    (
        ((-$y + isqrt($y**2 - 4 * $x * $z)) / (2 * $x)),
        ((-$y - isqrt($y**2 - 4 * $x * $z)) / (2 * $x)),
    );
}

my ($x1, $x2) = integer_quadratic_formula(1, $d, -$n);

printf("n = %s * %s\n", abs($x1), abs($x2));

if (abs($x1) * abs($x2) != $n) {
    die "error: $x1 * $x2 != $n\n";
}
