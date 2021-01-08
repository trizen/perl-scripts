#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 10 January 2019
# https://github.com/trizen

# Two fast algorithms for computing the sum of number of unitary divisors from 1 to n.
#   a(n) = Sum_{k=1..n} usigma_0(k)

# Based on the formula:
#   a(n) = Sum_{k=1..n} moebius(k)^2 * floor(n/k)

# See also:
#   https://oeis.org/A034444    -- Partial sums of A034444: sum of number of unitary divisors from 1 to n.
#   https://oeis.org/A180361    -- Sum of number of unitary divisors (A034444) from 1 to 10^n
#   https://oeis.org/A268732    -- Sum of the numbers of divisors of gcd(x,y) with x*y <= n.

# Asymptotic formula:
#   a(n) ~ n*log(n)/zeta(2) + O(n)

# Better asymptotic formula:
#   a(n) ~ (n/zeta(2))*(log(n) + 2*γ - 1 - c) + O(sqrt(n) * log(n))
#
# where γ is the Euler-Mascheroni constant and c = 2*zeta'(2)/zeta(2) = -1.1399219861890656127997287200...

use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);
use Math::AnyNum qw(:overload zeta EulerGamma round);

sub squarefree_count ($n) {
    my $count = 0;

    my $k = 1;
    foreach my $mu (moebius(1, sqrtint($n))) {
        if ($mu) {
            $count += $mu * divint($n, $k * $k);
        }
        ++$k;
    }

    return $count;
}

sub asymptotic_formula($n) {

    # c = 2*Zeta'(2)/Zeta(2) = (12 * Zeta'(2))/π^2 = 2 (-12 log(A) + γ + log(2) + log(π))
    my $c = -1.13992198618906561279972872003946000480696456161386195911639472087583455473348121357;

    # Asymptotic formula based on Merten's theorem (1874) (see: https://oeis.org/A064608)
    ($n / zeta(2)) * (log($n) + 2 * EulerGamma - 1 - $c);
}

sub unitary_divisors_partial_sum_1 ($n) {    # O(sqrt(n)) complexity

    my $total = 0;

    my $s = sqrtint($n);
    my $u = divint($n, $s + 1);

    my $prev = squarefree_count($n);

    for my $k (1 .. $s) {
        my $curr = squarefree_count(divint($n, $k + 1));
        $total += $k * ($prev - $curr);
        $prev = $curr;
    }

    forsquarefree {
        $total += divint($n, $_);
    } $u;

    return $total;
}

sub unitary_divisors_partial_sum_2 ($n) {    # based on formula by Jerome Raulin (https://oeis.org/A064608)

    my $total = 0;

    my $k = 1;
    foreach my $mu (moebius(1, sqrtint($n))) {
        if ($mu) {

            my $t = 0;
            foreach my $j (1 .. sqrtint(divint($n, $k * $k))) {
                $t += divint($n, $j * $k * $k);
            }

            my $r = sqrtint(divint($n, $k * $k));
            $total += $mu * (2 * $t - $r * $r);
        }
        ++$k;
    }

    return $total;
}

say join(', ', map { unitary_divisors_partial_sum_1($_) } 1 .. 20);
say join(', ', map { unitary_divisors_partial_sum_2($_) } 1 .. 20);

foreach my $k (0 .. 7) {

    my $n = 10**$k;
    my $t = unitary_divisors_partial_sum_2($n);
    my $u = asymptotic_formula($n);

    printf("a(10^%s) = %10s ~ %-15s -> %s\n", $k, $t, round($u, -2), $t / $u);
}

__END__
[0, 1, 3, 5, 7, 9, 13, 15, 17, 19, 23, 25, 29, 31, 35, 39, 41, 43, 47, 49, 53]
[0, 1, 3, 5, 7, 9, 13, 15, 17, 19, 23, 25, 29, 31, 35, 39, 41, 43, 47, 49, 53]

a(10^0)  =            1 ~ 0.79            -> 1.27085398285349342897812915198984638968899591751
a(10^1)  =           23 ~ 21.87           -> 1.05182461403816051734935994402113331145060974294
a(10^2)  =          359 ~ 358.65          -> 1.00098140095602073835866744824992972185806123685
a(10^3)  =         4987 ~ 4986.28         -> 1.00014357239778054254970740667091143421188177813
a(10^4)  =        63869 ~ 63860.88        -> 1.00012715302552355451250212258735392366329621935
a(10^5)  =       778581 ~ 778589.19       -> 0.999989484576929013867264739526374966823956960403
a(10^6)  =      9185685 ~ 9185695.75      -> 0.99999882923368455522780513812504287278271814501
a(10^7)  =    105854997 ~ 105854996.37    -> 1.00000000598372061072117962943109677794267023891
a(10^8)  =   1198530315 ~ 1198530351.90   -> 0.999999969211002320383540850995519903094748492418
a(10^9)  =  13385107495 ~ 13385107401.37  -> 1.00000000699496540213133746406895764726726792391
a(10^10) = 147849112851 ~ 147849112837.28 -> 1.00000000009281141854332921757852421030396550125
