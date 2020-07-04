#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 10 January 2018
# https://github.com/trizen

# Sum of the sigma(k) function, for 1 <= k <= n, where `sigma(k)` is `Sum_{d|k} d`.

# See also:
#   https://oeis.org/A024916
#   https://oeis.org/A072692

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(faulhaber_sum isqrt);

sub partial_sum_of_sigma {    # O(sqrt(n)) complexity
    my ($n) = @_;

    my $s = isqrt($n);
    my $u = int($n / ($s + 1));

    my $sum  = 0;
    my $prev = faulhaber_sum($n, 1);    # n-th triangular number

    foreach my $k (1 .. $s) {
        my $curr = faulhaber_sum(int($n/($k+1)), 1);
        $sum += $k * ($prev - $curr);
        $prev = $curr;
    }

    foreach my $k (1 .. $u) {
        $sum += $k * int($n / $k);
    }

    return $sum;
}

foreach my $k (0 .. 10) {
    say "a(10^$k) = ", partial_sum_of_sigma(10**$k);
}

__END__
a(10^0) = 1
a(10^1) = 87
a(10^2) = 8299
a(10^3) = 823081
a(10^4) = 82256014
a(10^5) = 8224740835
a(10^6) = 822468118437
a(10^7) = 82246711794796
a(10^8) = 8224670422194237
a(10^9) = 822467034112360628
