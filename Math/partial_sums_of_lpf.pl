#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 20 July 2020
# https://github.com/trizen

# Algorithm with sublinear time for computing:
#
#   Sum_{k=2..n} lpf(k)
#
# where:
#   lpf(k) = the least prime factor of k

# See also:
#   https://projecteuler.net/problem=521

use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub partial_sums_of_lpf($n) {

    my $t = 0;
    my $s = sqrtint($n);

    forprimes {
        $t = addint($t, mulint($_, rough_count(divint($n,$_), $_)));
    } $s;

    addint($t, sum_primes(next_prime($s), $n));
}

foreach my $k (1..10) {
    printf("S(10^%d) = %s\n", $k, partial_sums_of_lpf(powint(10, $k)));
}

__END__
S(10^1)  = 28
S(10^2)  = 1257
S(10^3)  = 79189
S(10^4)  = 5786451
S(10^5)  = 455298741
S(10^6)  = 37568404989
S(10^7)  = 3203714961609
S(10^8)  = 279218813374515
S(10^9)  = 24739731010688477
S(10^10) = 2220827932427240957
S(10^11) = 201467219561892846337
S(10^12) = 18435592284459044389811
