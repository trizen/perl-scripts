#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 24 November 2018
# https://github.com/trizen

# A new algorithm for computing the partial-sums of the prime omega function `ω(k)`, for `1 <= k <= n`:
#   a(n) = Sum_{k=1..n} ω(k)

# Based on the formula:
#   Sum_{k=1..n} ω(k) = Sum_{p prime <= n} floor(n/p)

# Example:
#    a(10^1) = 11
#    a(10^2) = 171
#    a(10^3) = 2126
#    a(10^4) = 24300
#    a(10^5) = 266400
#    a(10^6) = 2853708
#    a(10^7) = 30130317
#    a(10^8) = 315037281
#    a(10^9) = 3271067968
#    a(10^10) = 33787242719
#    a(10^11) = 347589015681
#    a(10^12) = 3564432632541

# See also:
#   https://oeis.org/A013939
#   https://oeis.org/A064182
#   https://en.wikipedia.org/wiki/Prime_omega_function
#   https://en.wikipedia.org/wiki/Prime-counting_function
#   https://trizenx.blogspot.com/2018/11/partial-sums-of-arithmetical-functions.html

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(forprimes prime_count sqrtint);

sub prime_omega_partial_sum ($n) {     # O(sqrt(n)) complexity

    my $total = 0;

    my $s = sqrtint($n);
    my $u = int($n / ($s + 1));

    for my $k (1 .. $s) {
        $total += $k * prime_count(int($n/($k+1))+1, int($n/$k));
    }

    forprimes {
        $total += int($n/$_);
    } $u;

    return $total;
}

sub prime_omega_partial_sum_test ($n) {    # just for testing
    my $total = 0;

    forprimes {
        $total += int($n/$_);
    } $n;

    return $total;
}

for my $m (1 .. 10) {

    my $n = int rand 100000;

    my $t1 = prime_omega_partial_sum($n);
    my $t2 = prime_omega_partial_sum_test($n);

    die "error: $t1 != $t2" if ($t1 != $t2);

    say "Sum_{k=1..$n} omega(k) = $t1";
}

__END__
Sum_{k=1..62429} omega(k) = 163587
Sum_{k=1..80890} omega(k) = 213922
Sum_{k=1..82192} omega(k) = 217486
Sum_{k=1..97784} omega(k) = 260299
Sum_{k=1..16940} omega(k) = 42156
Sum_{k=1..42413} omega(k) = 109555
Sum_{k=1..18647} omega(k) = 46596
Sum_{k=1..18716} omega(k) = 46776
Sum_{k=1..56593} omega(k) = 147768
Sum_{k=1..65034} omega(k) = 170664
