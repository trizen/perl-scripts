#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 24 November 2018
# https://github.com/trizen

# A new algorithm for computing the partial-sums of the generalized prime omega function `ω_m(k)`, for `1 <= k <= n`:
#   A_m(n) = Sum_{k=1..n} ω_m(k)
#
# where:
#     ω_m(n) = n^m * Sum_{p|n} 1/p^m

# Based on the formula:
#   Sum_{k=1..n} ω_m(k) = Sum_{p prime <= n} F_m(floor(n/p))
#
# where F_n(x) is Faulhaber's formula.

# Example for `m=0`:
#   A_0(10^1) = 11
#   A_0(10^2) = 171
#   A_0(10^3) = 2126
#   A_0(10^4) = 24300
#   A_0(10^5) = 266400
#   A_0(10^6) = 2853708
#   A_0(10^7) = 30130317
#   A_0(10^8) = 315037281
#   A_0(10^9) = 3271067968
#   A_0(10^10) = 33787242719
#   A_0(10^11) = 347589015681
#   A_0(10^12) = 3564432632541

# Example for `m=1`:
#   A_1(10^1) = 25
#   A_1(10^2) = 2298
#   A_1(10^3) = 226342
#   A_1(10^4) = 22616110
#   A_1(10^5) = 2261266482
#   A_1(10^6) = 226124236118
#   A_1(10^7) = 22612374197143
#   A_1(10^8) = 2261237139656553
#   A_1(10^9) = 226123710243814636
#   A_1(10^10) = 22612371006991736766
#   A_1(10^11) = 2261237100241987653515
#   A_1(10^12) = 226123710021083492369813

# Example for `m=2`:
#   A_2(10^1) = 75
#   A_2(10^2) = 59962
#   A_2(10^3) = 58403906
#   A_2(10^4) = 58270913442
#   A_2(10^5) = 58255785988898
#   A_2(10^6) = 58254390385024132
#   A_2(10^7) = 58254229074894448703
#   A_2(10^8) = 58254214780225801032503
#   A_2(10^9) = 58254213248247357411667320
#   A_2(10^10) = 58254213116747777047390609694
#   A_2(10^11) = 58254213101385832019517484266265
#   A_2(10^12) = 58254213099991292350208499967189227

# Asymptotic formulas:
#   A_1(n) ~ 0.4522474200410654985065... * n*(n+1)/2               (see: https://oeis.org/A085548)
#   A_2(n) ~ 0.1747626392994435364231... * n*(n+1)*(2*n+1)/6       (see: https://oeis.org/A085541)

# For `m >= 1`, `A_m(n)` can be described asymptotically in terms of the prime zeta function:
#   A_m(n) ~ F_m(n) * P(m+1)
#
# where P(s) is defined as:
#   P(s) = Sum_{p prime >= 2} 1/p^s

# OEIS sequences:
#   https://oeis.org/A013939     -- Partial sums of sequence A001221 (number of distinct primes dividing n).
#   https://oeis.org/A064182     -- Sum_{k <= 10^n} number of distinct primes dividing k.

# See also:
#   https://en.wikipedia.org/wiki/Prime_omega_function
#   https://en.wikipedia.org/wiki/Prime-counting_function
#   https://trizenx.blogspot.com/2018/11/partial-sums-of-arithmetical-functions.html

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(faulhaber_sum ipow);
use ntheory qw(forprimes prime_count sqrtint is_prime);

sub prime_omega_partial_sum ($n, $m) {     # O(sqrt(n)) complexity

    my $total = 0;

    my $s = sqrtint($n);
    my $u = int($n / ($s + 1));

    for my $k (1 .. $s) {
        $total += faulhaber_sum($k, $m) * prime_count(int($n/($k+1))+1, int($n/$k));
    }

    forprimes {
        $total += faulhaber_sum(int($n/$_), $m);
    } $u;

    return $total;
}

sub prime_omega_partial_sum_2 ($n, $m) {     # O(sqrt(n)) complexity

    my $total = 0;
    my $s = sqrtint($n);

    for my $k (1 .. $s) {
        $total += ipow($k, $m) * prime_count(int($n/$k));
        $total += faulhaber_sum(int($n/$k), $m) if is_prime($k);
    }

    $total -= faulhaber_sum($s, $m) * prime_count($s);

    return $total;
}

sub prime_omega_partial_sum_test ($n, $m) {      # just for testing
    my $total = 0;

    forprimes {
        $total += faulhaber_sum(int($n/$_), $m);
    } $n;

    return $total;
}

for my $m (0 .. 10) {

    my $n = int rand 100000;

    my $t1 = prime_omega_partial_sum($n, $m);
    my $t2 = prime_omega_partial_sum_2($n, $m);
    my $t3 = prime_omega_partial_sum_test($n, $m);

    die "error: $t1 != $t2" if ($t1 != $t2);
    die "error: $t1 != $t3" if ($t1 != $t3);

    say "Sum_{k=1..$n} omega_$m(k) = $t1";
}

__END__
Sum_{k=1..93178} omega_0(k) = 247630
Sum_{k=1..60545} omega_1(k) = 828906439
Sum_{k=1..61222} omega_2(k) = 13368082621946
Sum_{k=1..58175} omega_3(k) = 220463446471253532
Sum_{k=1..26576} omega_4(k) = 94816277435320229002
Sum_{k=1..17978} omega_5(k) = 96085844643312478233603
Sum_{k=1..99336} omega_6(k) = 112956550182103434253591001302255
Sum_{k=1..15217} omega_7(k) = 1459563487599016502195229269710
Sum_{k=1..62565} omega_8(k) = 3271462737352430519765722633491562894793
Sum_{k=1..91318} omega_9(k) = 4007044838270388920307792726568428120477189405
Sum_{k=1..28834} omega_10(k) = 514524955177931497535073881648700561462698676
