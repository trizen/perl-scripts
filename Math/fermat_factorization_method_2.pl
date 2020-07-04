#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 13 September 2017
# https://github.com/trizen

# Fermat's factorization method.

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

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(vecprod sqrtint is_prime is_square valuation);

sub fermat_factorization ($n) {

    # Check for primes and negative numbers
    return ()   if ($n <= 1);
    return ($n) if is_prime($n);

    # Check for divisibility by 2
    if (!($n & 1)) {
        my $v = valuation($n, 2);
        return ((2) x $v, __SUB__->($n >> $v));
    }

    my $p = sqrtint($n);
    my $q = $p * $p - $n;

    until (is_square($q)) {
        $q += 2 * $p++ + 1;
    }

    my $s = sqrtint($q);

    my ($x1, $x2) = (
        ($p + $s),
        ($p - $s),
    );

    return sort { $a <=> $b } (
        __SUB__->($x1),
        __SUB__->($x2)
    );
}

foreach my $n (160587846247027, 5040, 65127835124, 6469693230) {

    my @f = fermat_factorization($n);
    say join(' * ', @f), " = $n";

    die 'error' if vecprod(@f) != $n;
}
