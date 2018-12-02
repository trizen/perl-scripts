#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 02 December 2018
# https://github.com/trizen

# A nice algorithm in terms of the prime-counting function for computing the number of prime powers <= n.
#   a(n) = Sum_{k=1..floor(log_2(n))} π(floor(n^(1/k)))

# Example: a(10^n) for n=1..15:
#   a(10^1)  = 7
#   a(10^2)  = 35
#   a(10^3)  = 193
#   a(10^4)  = 1280
#   a(10^5)  = 9700
#   a(10^6)  = 78734
#   a(10^7)  = 665134
#   a(10^8)  = 5762859
#   a(10^9)  = 50851223
#   a(10^10) = 455062595
#   a(10^11) = 4118082969
#   a(10^12) = 37607992088
#   a(10^13) = 346065767406
#   a(10^14) = 3204942420923
#   a(10^15) = 29844572385358

# See also:
#   https://oeis.org/A025528
#   https://oeis.org/A267712
#   https://en.wikipedia.org/wiki/Prime-counting_function
#   https://trizenx.blogspot.com/2018/11/partial-sums-of-arithmetical-functions.html

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(faulhaber_sum);
use ntheory qw(vecsum logint sqrtint rootint prime_count is_prime_power forprimes);

sub prime_power_count($n) {
    vecsum(map { prime_count(rootint($n, $_)) } 1 .. logint($n, 2));
}

foreach my $n (1 .. 10) {
    say "a(10^$n) = ", prime_power_count(10**$n);
}
