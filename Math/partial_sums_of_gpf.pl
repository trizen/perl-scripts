#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 20 July 2020
# https://github.com/trizen

# Algorithm with sublinear time for computing:
#
#   Sum_{k=2..n} gpf(k)
#
# where:
#   gpf(k) = the greatest prime factor of k

# See also:
#   https://projecteuler.net/problem=642

use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub partial_sums_of_gpf($n) {

    my $t = 0;
    my $s = sqrtint($n);

    forprimes {
        $t = addint($t, mulint($_, smooth_count(divint($n, $_), $_)));
    } $s;

    for(my $p = next_prime($s); $p <= $n; $p = next_prime($p)) {

        my $u = divint($n,$p);
        my $r = divint($n,$u);

        $t = addint($t, mulint($u, sum_primes($p,$r)));
        $p = $r;
    }

    return $t;
}

foreach my $k (1..10) {
    printf("S(10^%d) = %s\n", $k, partial_sums_of_gpf(powint(10, $k)));
}

__END__
S(10^1)  = 32
S(10^2)  = 1915
S(10^3)  = 135946
S(10^4)  = 10118280
S(10^5)  = 793111753
S(10^6)  = 64937323262
S(10^7)  = 5494366736156
S(10^8)  = 476001412898167
S(10^9)  = 41985754895017934
S(10^10) = 3755757137823525252
S(10^11) = 339760245382396733607
S(10^12) = 31019315736720796982142
