#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 01 April 2018
# https://github.com/trizen

# A new integer factorization method, based on continued fraction square root convergents.

# Similar to solving the Pell equation:
#   x^2 - d*y^2 = 1, where `d` is known.

# See also:
#   https://oeis.org/A003285
#   https://en.wikipedia.org/wiki/Pell%27s_equation

use 5.020;
use strict;
use warnings;

use integer;
use experimental qw(signatures);

use ntheory qw(
    is_prime gcd mulmod addmod sqrtint
    is_square vecprod vecany valuation urandomm
);

sub pell_factorization ($n) {

    # Check for primes and negative numbers
    return ()   if ($n <= 1);
    return ($n) if is_prime($n);

    # Check for perfect squares
    if (is_square($n)) {
        return sort { $a <=> $b } (
            (__SUB__->(sqrtint($n))) x 2
        );
    }

    # Check for divisibility by 2
    if (!($n & 1)) {
        my $v = valuation($n, 2);
        return ((2) x $v, __SUB__->($n >> $v));
    }

    my $x = sqrtint($n);
    my $y = $x;
    my $z = 1;

    my $r = $x + $y;

    my ($e1, $e2) = (1, 0);
    my ($f1, $f2) = (0, 1);

    for (; ;) {

        $y = $r * $z - $y;
        $z = int(($n - $y * $y) / $z);
        $r = int(($x + $y) / $z);

        my $a0 = addmod(mulmod($x, $f2, $n), $e2, $n);
        my $b0 = mulmod($a0, $a0, $n);

        if (is_square($b0)) {
            my $g = gcd($a0 - sqrtint($b0), $n);

            if ($g > 1 and $g < $n) {
                return sort { $a <=> $b } (
                    __SUB__->($g),
                    __SUB__->($n/$g)
                );
            }
        }

        foreach my $t (
            addmod(addmod(addmod($e2, $e2, $n), $f2, $n), $x, $n),
            addmod(addmod($e2, $f2, $n), $f2, $n),
            addmod($e2, mulmod($f2, $x, $n), $n),
            addmod($e2, $f2, $n),
            $e2,
        ) {
            my $g = gcd($t, $n);

            if ($g > 1 and $g < $n) {
                return sort { $a <=> $b } (
                    __SUB__->($g),
                    __SUB__->($n/$g)
                );
            }
        }

        ($f1, $f2) = ($f2, addmod(mulmod($r, $f2, $n), $f1, $n));
        ($e1, $e2) = ($e2, addmod(mulmod($r, $e2, $n), $e1, $n));
    }
}

foreach my $k (2..48) {
    my $n = urandomm(1 << $k) + 2;

    my @factors = pell_factorization($n);

    die 'error' if vecprod(@factors) != $n;
    die 'error' if vecany { !is_prime($_) } @factors;

    say "$n = ", join(' * ', @factors);
}
