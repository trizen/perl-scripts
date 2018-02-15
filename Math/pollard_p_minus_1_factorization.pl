#!/usr/bin/perl

# Simple implementation of Pollard's p−1 integer factorization algorithm. (unoptimized)

# See also:
#   https://en.wikipedia.org/wiki/Pollard%27s_p_%E2%88%92_1_algorithm

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(:overload powmod gcd lcm valuation is_prime);

sub pollard_p1_random {
    my ($n) = @_;

    return () if $n <= 1;
    return $n if is_prime($n);

    if ($n % 2 == 0) {
        my $v = valuation($n, 2);
        return ((2) x $v, pollard_p1_random($n >> $v));
    }

    for (
        my ($i, $k) = (1, 1);
        $k = lcm($k, ++$i);
    ) {

        my $x = powmod(2, $k, $n);
        my $g = gcd($x-1, $n);

        if ($g != 1 and $g != $n) {
            return sort {$a <=> $b} (
                pollard_p1_random($g),
                pollard_p1_random($n/$g)
            );
        }
    }
}

say join(', ', pollard_p1_random(25889*46511));
say join(', ', pollard_p1_random(419763345));
say join(', ', pollard_p1_random(5040));
say join(', ', pollard_p1_random(12129569695640600539));
say join(', ', pollard_p1_random(38568900844635025971879799293495379321));
