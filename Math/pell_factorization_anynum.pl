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

use experimental qw(signatures);

use ntheory qw(is_prime vecprod vecany);
use Math::AnyNum qw(:overload irand isqrt is_square valuation gcd round);

sub pell_factorization ($n) {

    # Check for primes and negative numbers
    return ()   if ($n <= 1);
    return ($n) if is_prime($n);

    # Check for perfect squares
    if (is_square($n)) {
        return sort { $a <=> $b } (
            (__SUB__->(isqrt($n))) x 2
        );
    }

    # Check for divisibility by 2
    if (!($n & 1)) {
        my $v = valuation($n, 2);
        return ((2) x $v, __SUB__->($n >> $v));
    }

    my $x = isqrt($n);
    my $y = $x;
    my $z = 1;

    my $r = 1;

    my ($e1, $e2) = (1, 0);
    my ($f1, $f2) = (0, 1);

    for (; ;) {

        $y = round(($x + $y) / $z) * $z - $y;
        $z = round(($n - $y * $y) / $z);
        $r = round(($x + $y) / $z);

        foreach my $t (
            $e2 + $e2 + $f2 + $x,
            $e2 + $f2 + $f2,
            $e2 + $f2 * $x,
            $e2 + $f2,
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

        ($f1, $f2) = ($f2, ($r * $f2 + $f1) % $n);
        ($e1, $e2) = ($e2, ($r * $e2 + $e1) % $n);
    }
}

foreach my $k (2 .. 48) {
    my $n = irand(2, 1 << $k);

    my @factors = pell_factorization($n);

    die 'error' if vecprod(@factors) != $n;
    die 'error' if vecany { !is_prime($_) } @factors;

    say "$n = ", join(' * ', @factors);
}
