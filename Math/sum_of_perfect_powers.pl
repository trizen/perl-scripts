#!/usr/bin/perl

# Efficient formula for computing the sum of perfect powers <= n.

# Formula:
#   a(n) = faulhaber(n,1) - Sum_{1..floor(log_2(n))} mu(k) * (faulhaber(floor(n^(1/k)), k) - 1)
#        = 1 - Sum_{2..floor(log_2(n))} mu(k) * (faulhaber(floor(n^(1/k)), k) - 1)
#
# where:
#   faulhaber(n,k) = Sum_{j=1..n} j^k.

# See also:
#   https://oeis.org/A069623

use 5.036;
use ntheory      qw(moebius);
use Math::AnyNum qw(faulhaber_sum sum ipow iroot ilog2);

sub perfect_power_sum ($n) {
    1 - sum(map { moebius($_) * (faulhaber_sum(iroot($n, $_), $_) - 1) } 2 .. ilog2($n));
}

foreach my $n (0 .. 15) {
    printf("a(10^%d) = %s\n", $n, perfect_power_sum(ipow(10, $n)));
}

__END__
a(10^0) = 1
a(10^1) = 22
a(10^2) = 452
a(10^3) = 13050
a(10^4) = 410552
a(10^5) = 11888199
a(10^6) = 361590619
a(10^7) = 11120063109
a(10^8) = 345454923761
a(10^9) = 10800726331772
a(10^10) = 338846269199225
a(10^11) = 10659098451968490
a(10^12) = 335867724220740686
a(10^13) = 10595345580446344714
a(10^14) = 334502268562161605300
a(10^15) = 10566065095217905939231
