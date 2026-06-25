#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 23 June 2026
# https://github.com/trizen

# A sublinear algorithm with O(sqrt(n)) complexity for computing the partial-sums of the `usigma_j(k)` function:
#
#   Sum_{k=1..n} usigma_j(k)
#
# for any integer j >= 0.

# See also:
#   https://oeis.org/A180361    -- Sum of number of unitary divisors (A034444) from 1 to 10^n.
#   https://oeis.org/A064608    -- Partial sums of A034444: sum of number of unitary divisors from 1 to n.
#   https://oeis.org/A064609    -- Partial sums of A034448: sum of unitary divisors from 1 to n.
#   https://en.wikipedia.org/wiki/Faulhaber%27s_formula
#   https://trizenx.blogspot.com/2018/11/partial-sums-of-arithmetical-functions.html

use 5.036;
use Math::GMPz;
use Math::Prime::Util 0.74 qw(:all);

prime_set_config(bigint => 'Math::GMPz');

sub usigma0_sum ($n) {

    my $total = 0;

    foreach my $k (1 .. sqrtint($n)) {

        my $mu = moebius($k) || next;

        my $tmp = 0;
        foreach my $j (1 .. sqrtint(int($n / $k / $k))) {
            $tmp += int($n / $j / $k / $k);
        }

        $total += $mu * (2 * $tmp - powint(sqrtint(int($n / $k / $k)), 2));
    }

    return $total;
}

sub usigma_sum ($n, $s) {

    if ($s == 0) {
        return usigma0_sum($n);
    }

    my $total = 0;

    foreach my $k (1 .. sqrtint($n)) {
        my $mu = moebius($k) || next;

        my $N     = divint($n, mulint($k, $k));
        my $sqrtN = sqrtint($N);

        my $term = 0;
        foreach my $j (1 .. $sqrtN) {
            $term = addint($term, powersum(divint($N, $j), $s));
            $term = addint($term, mulint(powint($j, $s), divint($N, $j)));
        }

        my $inner_sum = subint($term, mulint(powersum($sqrtN, $s), $sqrtN));
        $total = addint($total, vecprod($mu, powint($k, $s), $inner_sum));
    }

    return $total;
}

my $k = 1;
foreach my $n (1 .. 10) {    # takes ~1s
    say "S(10^$n, $k) = ", usigma_sum(powint(10, $n), $k);
}

__END__
S(10^1, 0) = 23
S(10^2, 0) = 359
S(10^3, 0) = 4987
S(10^4, 0) = 63869
S(10^5, 0) = 778581
S(10^6, 0) = 9185685
S(10^7, 0) = 105854997
S(10^8, 0) = 1198530315
S(10^9, 0) = 13385107495
S(10^10, 0) = 147849112851
S(10^11, 0) = 1618471517571
S(10^12, 0) = 17584519050293
S(10^13, 0) = 189843229312125
S(10^14, 0) = 2038412681323151

S(10^1, 1) = 76
S(10^2, 1) = 6889
S(10^3, 1) = 684578
S(10^4, 1) = 68425910
S(10^5, 1) = 6842185909
S(10^6, 1) = 684216736806
S(10^7, 1) = 68421643171218
S(10^8, 1) = 6842163918226589
S(10^9, 1) = 684216389063572134
S(10^10, 1) = 68421638885063570894

S(10^1, 2) = 436
S(10^2, 2) = 375133
S(10^3, 2) = 370665796
S(10^4, 2) = 370254727758
S(10^5, 2) = 370213445135817
S(10^6, 2) = 370209307662665112
S(10^7, 2) = 370208891686152913102
S(10^8, 2) = 370208849789956504311825
S(10^9, 2) = 370208845552653020009655572
S(10^10, 2) = 370208845155401284720733402346
