#!/usr/bin/perl

# Formula due to Ramanujan for computing the nth-Bernoulli number.

# See also:
#   https://en.wikipedia.org/wiki/Bernoulli_number#Ramanujan's_congruences

use 5.020;
use warnings;

use experimental qw(signatures);

use List::Util qw(sum);
use Math::AnyNum qw(:overload binomial);

sub ramanujan_bernoulli_number ($n, $cache = {}) {

    return 1/2 if ($n   == 1);
    return 0   if ($n%2 == 1);

    $cache->{$n} //= do {
        (($n%6 == 4 ? -1/2 : 1) * ($n+3)/3 -
            sum(map {
                binomial($n+3, $n - 6*$_) * __SUB__->($n - 6*$_, $cache)
            } 1 .. ($n - $n%6) / 6)
        ) / binomial($n+3, $n)
    };
}

foreach my $i (0 .. 50) {
    printf "B%-3d = %s\n", 2 * $i, ramanujan_bernoulli_number(2 * $i);
}
