#!/usr/bin/perl

# Simple implementation of Pollard's p−1 integer factorization algorithm.

# See also:
#   https://en.wikipedia.org/wiki/Pollard%27s_p_%E2%88%92_1_algorithm

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(:overload powmod);
use ntheory qw(vecprod is_prime gcd valuation);

sub pollard_p1_factor {
    my ($n) = @_;

    return () if $n <= 1;
    return $n if is_prime($n);

    if ($n % 2 == 0) {
        my $v = valuation($n, 2);
        return ((2) x $v, pollard_p1_factor($n >> $v));
    }

    for (my ($t, $k) = (2, 2) ; ; ++$k) {

        $t = powmod($t, $k, $n);
        my $g = gcd($t - 1, $n);

        next if $g == 1;

        if ($g == $n) {
            $t *= $k;
            next;
        }

        return sort { $a <=> $b } (
            pollard_p1_factor($g),
            pollard_p1_factor($n / $g)
        );
    }
}

say join(', ', pollard_p1_factor(25889 * 46511));
say join(', ', pollard_p1_factor(419763345));
say join(', ', pollard_p1_factor(5040));
say join(', ', pollard_p1_factor(12129569695640600539));
say join(', ', pollard_p1_factor(2**42 + 1));
say join(', ', pollard_p1_factor(2**64 + 1));
say join(', ', pollard_p1_factor(38568900844635025971879799293495379321));

# Run some tests
foreach my $n (1 .. 10000) {
    my @factors = pollard_p1_factor($n);
    if ((grep { is_prime($_) } @factors) != @factors) {
        die "Composite factor for $n";
    }

    if (vecprod(@factors) != $n) {
        die "Incorrect factors for $n";
    }
}
