#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 16 March 2018
# https://github.com/trizen

# A simple implementation of Fermat's factorization method.

# See also:
#   https://en.wikipedia.org/wiki/Fermat%27s_factorization_method

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use ntheory qw(is_prime vecprod);
use Math::AnyNum qw(:overload isqrt is_square valuation);

sub fermat_factorization ($n) {

    # Check for primes and negative numbers
    return ()   if ($n <= 1);
    return ($n) if is_prime($n);

    # Check for divisibility by 2
    if (!($n & 1)) {
        my $v = valuation($n, 2);
        return ((2) x $v, __SUB__->($n >> $v));
    }

    my $q = 2 * isqrt($n);

    while (!is_square($q * $q - 4 * $n)) {
        $q += 2;
    }

    my $p = ($q + isqrt($q * $q - 4 * $n)) >> 1;

    return sort { $a <=> $b } (
        __SUB__->($p),
        __SUB__->($n / $p),
    );
}

foreach my $n (160587846247027, 5040, 65127835124, 6469693230) {

    my @f = fermat_factorization($n);
    say join(' * ', @f), " = $n";

    die 'error' if vecprod(@f) != $n;
}
