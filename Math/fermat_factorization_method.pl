#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 12 September 2017
# https://github.com/trizen

# Fermat's factorization method (derivation).

# Theorem:
#   If the absolute difference between the prime factors of a
#   semiprime `n` is known, then `n` can be factored in polynomial time.

# Based on the following quadratic equation:
#   x^2 + (a - b)*x - a*b = 0
#
# which has the solutions:
#   x₁ = -a
#   x₂ = +b

use 5.010;
use strict;
use warnings;

use ntheory qw(sqrtint is_prime is_power);

sub fermat_factorization {
    my ($n) = @_;

    if ($n <= 1 or is_prime($n)) {
        return $n;
    }

    my $t = $n << 2;

    for (my $d = 0 ; ; ++$d) {
        if (is_power($d*$d + $t, 2)) {

            my $q = sqrtint($d*$d + $t);

            my ($x1, $x2) = (
                ($q - $d) >> 1,
                ($q + $d) >> 1,
            );

            return sort { $a <=> $b } (
                fermat_factorization($x1),
                fermat_factorization($x2)
            );
        }
    }
}

foreach my $n (160587846247027, 5040, 65127835124, 6469693230) {
    say join(' * ', fermat_factorization($n)), " = $n";
}

__END__
12672269 * 12672383 = 160587846247027
2 * 2 * 2 * 2 * 3 * 3 * 5 * 7 = 5040
2 * 2 * 11 * 19 * 6359 * 12251 = 65127835124
2 * 3 * 5 * 7 * 11 * 13 * 17 * 19 * 23 * 29 = 6469693230
