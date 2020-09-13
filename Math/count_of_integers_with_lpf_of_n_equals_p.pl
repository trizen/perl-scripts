#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 15 March 2020
# https://github.com/trizen

# Given `n` and `p`, count the number of integers k <= n, such that:
#    lpf(k) = p
# where `lpf(k)` is the least prime factor of k.

# This is equivalent with the number of p-rough numbers <= floor(n/p).

# See also:
#   https://en.wikipedia.org/wiki/Rough_number

use 5.020;
use integer;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub count_with_lpf ($n, $p) {

    #~ return rough_count($n/$p, $p);

    if ($p > sqrt($n)) {
        return 1;
    }

    my $u = 0;
    my $t = $n / $p;

    for (my $q = 2 ; $q < $p ; $q = next_prime($q)) {

        my $v = __SUB__->($t - ($t % $q), $q);

        if ($v == 1) {
            $u += prime_count($q, $p - 1);
            last;
        }
        else {
            $u += $v;
        }
    }

    $t - $u;
}

foreach my $n (1 .. 10) {
    say "a(10^$n) for primes below 20: {", join(', ', map { count_with_lpf(powint(10, $n), $_) } @{primes(20)}), "}";
}

__END__
a(10^1)  for primes below 20: {5, 2, 1, 1, 1, 1, 1, 1}
a(10^2)  for primes below 20: {50, 17, 7, 4, 1, 1, 1, 1}
a(10^3)  for primes below 20: {500, 167, 67, 38, 21, 17, 11, 9}
a(10^4)  for primes below 20: {5000, 1667, 667, 381, 208, 160, 111, 95}
a(10^5)  for primes below 20: {50000, 16667, 6667, 3809, 2078, 1598, 1128, 950}
a(10^6)  for primes below 20: {500000, 166667, 66667, 38095, 20779, 15984, 11284, 9503}
a(10^7)  for primes below 20: {5000000, 1666667, 666667, 380953, 207792, 159840, 112830, 95017}
a(10^8)  for primes below 20: {50000000, 16666667, 6666667, 3809524, 2077921, 1598401, 1128285, 950134}
a(10^9)  for primes below 20: {500000000, 166666667, 66666667, 38095238, 20779221, 15984017, 11282835, 9501332}
a(10^10) for primes below 20: {5000000000, 1666666667, 666666667, 380952381, 207792208, 159840160, 112828349, 95013344}
