#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 27 November 2018
# https://github.com/trizen

# A nice algorithm in terms of the prime-counting function for computing partial sums of the generalized bigomega(n) function:
#   B_m(n) = Sum_{k=1..n} Ω_m(k)

# For `m=0`, we have:
#   B_0(n) = bigomega(n!)

# OEIS related sequences:
#   https://oeis.org/A025528
#   https://oeis.org/A022559
#   https://oeis.org/A071811
#   https://oeis.org/A154945  (0.55169329765699918...)
#   https://oeis.org/A286229  (0.19411816983263379...)

# Example for `B_0(n)`:
#    B_0(10^1) = 15
#    B_0(10^2) = 239
#    B_0(10^3) = 2877
#    B_0(10^4) = 31985
#    B_0(10^5) = 343614
#    B_0(10^6) = 3626619
#    B_0(10^7) = 37861249
#    B_0(10^8) = 392351272
#    B_0(10^9) = 4044220058
#    B_0(10^10) = 41518796555
#    B_0(10^11) = 424904645958

# Example for `B_1(n)`:
#   B_1(10^1) = 30
#   B_1(10^2) = 2815
#   B_1(10^3) = 276337
#   B_1(10^4) = 27591490
#   B_1(10^5) = 2758525172
#   B_1(10^6) = 275847515154
#   B_1(10^7) = 27584671195911
#   B_1(10^8) = 2758466558498626
#   B_1(10^9) = 275846649393437566
#   B_1(10^10) = 27584664891073330599
#   B_1(10^11) = 2758466488352698209587

# Example for `B_2(n)`:
#   B_2(10^1) = 82
#   B_2(10^2) = 66799
#   B_2(10^3) = 64901405
#   B_2(10^4) = 64727468210
#   B_2(10^5) = 64708096890744
#   B_2(10^6) = 64706281936598588
#   B_2(10^7) = 64706077322294843451
#   B_2(10^8) = 64706058761567362618628
#   B_2(10^9) = 64706056807390376400359474
#   B_2(10^10) = 64706056632561375736945155965
#   B_2(10^11) = 64706056612919470606889256184409

# Asymptotic formulas:
#   B_1(n) ~ 0.55169329765699918... * n*(n+1)/2
#   B_2(n) ~ 0.19411816983263379... * n*(n-1)*(2*n - 1)/6

# In general, for `m>=1`, we have the following asymptotic formula:
#   B_m(n) ~ (Sum_{k>=1} primezeta((m+1)*k)) * F_m(n)
#
# where F_n(x) is Faulhaber's formula and primezeta(s) is the prime zeta function.

# The prime zeta function is defined as:
#   primezeta(s) = Sum_{p prime >= 2} 1/p^s

# OEIS sequences:
#   https://oeis.org/A022559    -- Sum of exponents in prime-power factorization of n!.
#   https://oeis.org/A071811    -- Sum_{k <= 10^n} number of primes (counted with multiplicity) dividing k.

# See also:
#   https://en.wikipedia.org/wiki/Prime_zeta_function
#   https://en.wikipedia.org/wiki/Prime_omega_function
#   https://en.wikipedia.org/wiki/Prime-counting_function
#   https://trizenx.blogspot.com/2018/11/partial-sums-of-arithmetical-functions.html

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(faulhaber_sum ipow);
use ntheory qw(vecsum logint sqrtint rootint prime_count is_prime_power forprimes);

sub prime_power_count($n) {
    vecsum(map { prime_count(rootint($n, $_)) } 1 .. logint($n, 2));
}

sub prime_bigomega_partial_sum ($n, $m) {

    my $s = sqrtint($n);
    my $u = int($n/($s + 1));

    my $total = 0;
    my $prev = prime_power_count($n);

    for my $k (1 .. $s) {
        my $curr = prime_power_count(int($n/($k+1)));
        $total += faulhaber_sum($k, $m) * ($prev - $curr);
        $prev = $curr;
    }

    forprimes {
        foreach my $k (1 .. logint($u, $_)) {
            $total += faulhaber_sum(int($n / $_**$k), $m);
        }
    } $u;

    return $total;
}

sub prime_bigomega_partial_sum_2 ($n, $m) {

    my $s = sqrtint($n);
    my $total = 0;

    for my $k (1 .. $s) {
        $total += ipow($k, $m) * prime_power_count(int($n/$k));
        $total += faulhaber_sum(int($n/$k), $m) if is_prime_power($k);
    }

    $total -= prime_power_count($s) * faulhaber_sum($s, $m);

    return $total;
}

sub prime_bigomega_partial_sum_test ($n, $m) {    # just for testing
    my $total = 0;

    foreach my $k (1 .. $n) {
        if (is_prime_power($k)) {
            $total += faulhaber_sum(int($n/$k), $m);
        }
    }

    return $total;
}

for my $m (0 .. 10) {

    my $n = int rand 100000;

    my $t1 = prime_bigomega_partial_sum($n, $m);
    my $t2 = prime_bigomega_partial_sum_2($n, $m);
    my $t3 = prime_bigomega_partial_sum_test($n, $m);

    die "error: $t1 != $t2" if ($t1 != $t2);
    die "error: $t1 != $t3" if ($t1 != $t3);

    say "Sum_{k=1..$n} bigomega_$m(k) = $t1";
}

__END__
Sum_{k=1..64129} bigomega_0(k) = 217697
Sum_{k=1..80658} bigomega_1(k) = 1794616247
Sum_{k=1..14117} bigomega_2(k) = 182041102184
Sum_{k=1..42256} bigomega_3(k) = 64820877399946967
Sum_{k=1..94333} bigomega_4(k) = 54949545016977768030431
Sum_{k=1..67787} bigomega_5(k) = 280074038628976042168758675
Sum_{k=1..35346} bigomega_6(k) = 82191526450425222986408201316
Sum_{k=1..26871} bigomega_7(k) = 138516432841564488200009700415893
Sum_{k=1..37827} bigomega_8(k) = 35383863032817120893574255077390725080
Sum_{k=1..75109} bigomega_9(k) = 568264668321999976994584691196910905310669837
Sum_{k=1..86486} bigomega_10(k) = 90982066598399530764623907560522017063257428908802
