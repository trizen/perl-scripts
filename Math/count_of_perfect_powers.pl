#!/usr/bin/perl

# Efficient formula for counting the numbers of perfect powers <= n.

# Formula:
#   a(n) = n - Sum_{1..floor(log_2(n))} mu(k) * (floor(n^(1/k)) - 1)
#        = 1 - Sum_{2..floor(log_2(n))} mu(k) * (floor(n^(1/k)) - 1)

# See also:
#   https://oeis.org/A069623

use 5.036;
use ntheory qw(logint rootint moebius vecsum);

sub perfect_power_count ($n) {
    1 - vecsum(map { moebius($_) * (rootint($n, $_) - 1) } 2 .. logint($n, 2));
}

foreach my $n (0 .. 15) {
    printf("a(10^%d) = %s\n", $n, perfect_power_count(10**$n));
}

__END__
a(10^0) = 1
a(10^1) = 4
a(10^2) = 13
a(10^3) = 41
a(10^4) = 125
a(10^5) = 367
a(10^6) = 1111
a(10^7) = 3395
a(10^8) = 10491
a(10^9) = 32670
a(10^10) = 102231
a(10^11) = 320990
a(10^12) = 1010196
a(10^13) = 3184138
a(10^14) = 10046921
a(10^15) = 31723592
