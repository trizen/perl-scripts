#!/usr/bin/perl

# Simple implementation of Pollard's p−1 integer factorization algorithm.

# See also:
#   https://en.wikipedia.org/wiki/Pollard%27s_p_%E2%88%92_1_algorithm
#   https://trizenx.blogspot.com/2019/08/special-purpose-factorization-algorithms.html

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(is_prime logint);
use Math::AnyNum qw(:overload powmod gcd);

sub pollard_pm1_factor ($n, $B = logint($n, 2)**2) {

    return () if $n <= 1;
    return $n if is_prime($n);
    return 2  if $n % 2 == 0;

    my ($t, $g) = (2, 1);

    for my $k (2 .. $B) {

        $t = powmod($t, $k, $n);
        $g = gcd($t - 1, $n);

        $g <= 1  and next;
        $g >= $n and last;

        return $g;
    }

    return 1;
}

say pollard_pm1_factor(1204123279);                                #=> 25889
say pollard_pm1_factor(406816927495811038353579431);               #=> 9074269
say pollard_pm1_factor(38568900844635025971879799293495379321);    #=> 17495058332072672321
