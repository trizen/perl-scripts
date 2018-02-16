#!/usr/bin/perl

# Simple implementation of Pollard's p−1 integer factorization algorithm + Fermat's factorization method.

# See also:
#   https://en.wikipedia.org/wiki/Pollard%27s_p_%E2%88%92_1_algorithm
#   https://en.wikipedia.org/wiki/Fermat%27s_factorization_method

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(:overload powmod isqrt);
use ntheory qw(vecprod is_prime gcd is_square valuation);

sub pollard_p1_fermat_factor ($n) {

    return () if $n <= 1;
    return $n if is_prime($n);

    if ($n % 2 == 0) {
        my $v = valuation($n, 2);
        return ((2) x $v, __SUB__->($n >> $v));
    }

    my $p = isqrt(4 * $n);
    my $q = $p * $p - 4 * $n;

    for (my ($t, $k) = (2, 2) ; ; $k += 16) {

        $q += 2 * $p++ + 1;

        if (is_square($q)) {

            my $s = isqrt($q);

            my ($x1, $x2) = (
                ($p + $s) >> 1,
                ($p - $s) >> 1,
            );

            return sort { $a <=> $b } (
                __SUB__->($x1),
                __SUB__->($x2),
            );
        }

        $t = powmod($t, $k, $n);
        my $g = gcd($t - 1, $n);

        next if $g == 1;

        if ($g == $n) {
            $t = $k+1;
            next;
        }

        return sort { $a <=> $b } (
            __SUB__->($g),
            __SUB__->($n / $g)
        );
    }
}

say join(', ', pollard_p1_fermat_factor(25889 * 46511));
say join(', ', pollard_p1_fermat_factor(419763345));
say join(', ', pollard_p1_fermat_factor(5040));
say join(', ', pollard_p1_fermat_factor(12129569695640600539));
say join(', ', pollard_p1_fermat_factor(2**42 + 1));
say join(', ', pollard_p1_fermat_factor(2**64 + 1));
say join(', ', pollard_p1_fermat_factor(38568900844635025971879799293495379321));

# Run some tests
foreach my $n (1 .. 10000) {
    my @factors = pollard_p1_fermat_factor($n);
    if ((grep { is_prime($_) } @factors) != @factors) {
        die "Composite factor for $n";
    }

    if (vecprod(@factors) != $n) {
        die "Incorrect factors for $n";
    }
}
