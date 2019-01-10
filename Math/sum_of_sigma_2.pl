#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 10 January 2018
# https://github.com/trizen

# Sum of the sigma_2(k) function, for 1 <= k <= n, where `sigma_2(k)` is `Sum_{d|k} d^2`.

# See also:
#   https://oeis.org/A188138

use 5.010;
use strict;
use warnings;

use ntheory qw(sqrtint);
use Math::AnyNum qw(faulhaber_sum);

sub partial_sum_of_sigma2 {    # O(sqrt(n)) complexity
    my ($n) = @_;

    my $s = sqrtint($n);
    my $u = int($n / ($s + 1));

    my $sum  = 0;
    my $prev = faulhaber_sum($n, 2);

    foreach my $k (1 .. $s) {
        my $curr = faulhaber_sum(int($n / ($k + 1)), 2);
        $sum += $k * ($prev - $curr);
        $prev = $curr;
    }

    foreach my $k (1 .. $u) {
        $sum += $k * $k * int($n / $k);
    }

    return $sum;
}

foreach my $k (0 .. 9) {
    say "a(10^$k) = ", partial_sum_of_sigma2(10**$k);
}

__END__
a(10^0) = 1
a(10^1) = 469
a(10^2) = 407819
a(10^3) = 401382971
a(10^4) = 400757638164
a(10^5) = 400692683389101
a(10^6) = 400686363385965077
a(10^7) = 400685705322499946270
a(10^8) = 400685641565621401132515
a(10^9) = 400685635084923815073475174
