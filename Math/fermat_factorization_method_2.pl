#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 13 September 2017
# https://github.com/trizen

# Fermat's factorization method (derivation).

# This is a generalized version of Fermat's method, which works for any input.

# Theorem:
#   If the absolute difference between the prime factors of a
#   semiprime `n` is known, then `n` can be factored in polynomial time.

# Based on the following quadratic equation:
#   x^2 + (a - b)*x - a*b = 0
#
# which has the solutions:
#   x₁ = -a
#   x₂ = +b

# See also:
#   https://en.wikipedia.org/wiki/Fermat%27s_factorization_method

use 5.010;
use strict;
use warnings;

use ntheory qw(sqrtint is_prime is_power);

sub fermat_factorization {
    my ($n) = @_;

    if ($n <= 1 or is_prime($n)) {
        return $n;
    }

    $n <<= 2;  # multiply by 4

    my $p = sqrtint($n);
    my $q = $p * $p - $n;

    until (is_power($q, 2)) {
        $q += 2 * $p++ + 1;
    }

    my $s = sqrtint($q);

    my ($x1, $x2) = (
        ($p + $s) >> 1,
        ($p - $s) >> 1,
    );

    return sort { $a <=> $b } (
        fermat_factorization($x1),
        fermat_factorization($x2)
    );
}

foreach my $n (160587846247027, 5040, 65127835124, 6469693230) {
    say join(' * ', fermat_factorization($n)), " = $n";
}

__END__
12672269 * 12672383 = 160587846247027
2 * 2 * 2 * 2 * 3 * 3 * 5 * 7 = 5040
2 * 2 * 11 * 19 * 6359 * 12251 = 65127835124
2 * 3 * 5 * 7 * 11 * 13 * 17 * 19 * 23 * 29 = 6469693230
