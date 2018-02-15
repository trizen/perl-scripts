#!/usr/bin/perl

# Simple implementation of Pollard's p−1 integer factorization algorithm. (unoptimized)

# See also:
#   https://en.wikipedia.org/wiki/Pollard%27s_p_%E2%88%92_1_algorithm

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(:overload powmod gcd lcm valuation is_prime);

sub pollard_p1_factor {
    my ($n) = @_;

    return () if $n <= 1;
    return $n if is_prime($n);

    if ($n % 2 == 0) {
        my $v = valuation($n, 2);
        return ((2) x $v, pollard_p1_factor($n >> $v));
    }

    my ($t, $i, $k) = (2, 1, 1);

    for (;;) {

        my $x = powmod($t, $k, $n);
        my $g = gcd($x-1, $n);

        if ($g != 1) {

            if ($g == $n) {
                ++$t; next;
            }

            return sort { $a <=> $b } (
                pollard_p1_factor($g),
                pollard_p1_factor($n/$g)
            );
        }

        $k = lcm($k, ++$i);
    }
}

say join(', ', pollard_p1_factor(25889*46511));
say join(', ', pollard_p1_factor(419763345));
say join(', ', pollard_p1_factor(5040));
say join(', ', pollard_p1_factor(12129569695640600539));
say join(', ', pollard_p1_factor(2**64 + 1));
say join(', ', pollard_p1_factor(38568900844635025971879799293495379321));
