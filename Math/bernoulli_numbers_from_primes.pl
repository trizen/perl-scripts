#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13 May 2017
# https://github.com/trizen

# A very high-level computation of the nth-Bernoulli number, using prime numbers.

# Algorithm due to Kevin J. McGown (December 8, 2005)
# See his paper: "Computing Bernoulli Numbers Quickly"

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(factorial next_prime ceil float is_div);

sub bern_from_primes {
    my ($n) = @_;

    $n == 0 and return Math::AnyNum->one;
    $n == 1 and return Math::AnyNum->new('1/2');
    $n <  0 and return Math::AnyNum->nan;
    $n %  2 and return Math::AnyNum->zero;

    my $tau   = 6.28318530717958647692528676655900576839433879875;
    my $log2B = (log(4 * $tau * $n) / 2 + $n * log($n) - $n * log($tau) - $n) / log(2);

    local $Math::AnyNum::PREC = int($n + $log2B) + ($n <= 90 ? 18 : 0);

    my $K = factorial($n) * 2 / Math::AnyNum->tau**$n;
    my $d = 1;

    for (my $p = 2 ; $p <= $n + 1 ; $p = next_prime($p)) {
        if (is_div($n, $p - 1)) {
            $d *= $p;
        }
    }

    my $N = ceil(($K * $d)->root($n - 1));

    my $z = 1.0;
    for (my $p = 2 ; $p <= $N ; $p = next_prime($p)) {
        my $u = float($p)**$n;
        $z *= $u / ($u-1);
    }

    (-1)**($n / 2 + 1) * int(ceil($d * $K * $z)) / $d;
}

foreach my $n (0 .. 50) {
    printf "B%-3d = %s\n", 2 * $n, bern_from_primes(2 * $n);
}
