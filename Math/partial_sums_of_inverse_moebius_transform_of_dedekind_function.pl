#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 08 March 2019
# https://github.com/trizen

# Partial sums of the inverse Möbius transform of the Dedekind psi function.

# Definition, for m >= 0:
#
#   a(n) = Sum_{k=1..n} Sum_{d|k} ψ_m(d)
#        = Sum_{k=1..n} Sum_{d|k} 2^omega(k/d) * d^m
#        = Sum_{k=1..n} 2^omega(k) * F_m(floor(n/k))
#
# where `F_n(x)` are the Faulhaber polynomials.

# Asymptotic formula:
#   Sum_{k=1..n} Sum_{d|k} ψ_m(d) ~ F_m(n) * (zeta(m+1)^2 / zeta(2*(m+1)))
#                                 ~ (n^(m+1) * zeta(m+1)^2) / ((m+1) * zeta(2*(m+1)))

# For m=1, we have:
#   a(n) ~ (5/4) * n^2.
#   a(n) = Sum_{k=1..n} A060648(k).
#   a(n) = Sum_{k=1..n} Sum_{d|k} 2^omega(k/d) * d.
#   a(n) = Sum_{k=1..n} Sum_{d|k} A001615(d).
#   a(n) = (1/2)*Sum_{k=1..n} 2^omega(k) * floor(n/k) * floor(1 + n/k).

# Related OEIS sequences:
#   https://oeis.org/A064608 -- Partial sums of A034444: sum of number of unitary divisors from 1 to n.
#   https://oeis.org/A061503 -- Sum_{k<=n} (tau(k^2)), where tau is the number of divisors function.

# See also:
#   https://en.wikipedia.org/wiki/Dedekind_psi_function
#   https://trizenx.blogspot.com/2018/11/partial-sums-of-arithmetical-functions.html

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(faulhaber_sum);
use ntheory qw(sqrtint rootint factor_exp moebius);

sub inverse_moebius_of_dedekind_partial_sum ($n, $m) {

    my $lookup_size      = 2 + 2 * rootint($n, 3)**2;
    my @omega_sum_lookup = (0);

    for my $k (1 .. $lookup_size) {
        $omega_sum_lookup[$k] = $omega_sum_lookup[$k - 1] + 2**factor_exp($k);
    }

    my $s  = sqrtint($n);
    my @mu = moebius(0, $s);

    my sub R($n) {    # A064608(n) = Sum_{k=1..n} 2^omega(k)

        if ($n <= $lookup_size) {
            return $omega_sum_lookup[$n];
        }

        my $total = 0;

        foreach my $k (1 .. sqrtint($n)) {

            $mu[$k] || next;

            my $tmp = 0;
            foreach my $j (1 .. sqrtint(int($n / $k / $k))) {
                $tmp += int($n / $j / $k / $k);
            }

            $total += $mu[$k] * (2 * $tmp - sqrtint(int($n / $k / $k))**2);
        }

        return $total;
    }

    my $total = 0;

    for my $k (1 .. $s) {
        $total += 2**factor_exp($k) * faulhaber_sum(int($n / $k), $m);
        $total += $k**$m * R(int($n / $k));
    }

    $total -= R($s) * faulhaber_sum($s, $m);

    return $total;
}

sub inverse_moebius_of_dedekind_partial_sum_test ($n, $m) {    # just for testing
    my $total = 0;

    foreach my $k (1 .. $n) {
        $total += 2**factor_exp($k) * faulhaber_sum(int($n / $k), $m);
    }

    return $total;
}

for my $m (0 .. 10) {

    my $n = int(rand(1000));

    my $t1 = inverse_moebius_of_dedekind_partial_sum($n, $m);
    my $t2 = inverse_moebius_of_dedekind_partial_sum_test($n, $m);

    die "error: $t1 != $t2" if $t1 != $t2;

    say "Sum_{k=1..$n} Sum_{d|k} ψ_$m(d) = $t1";
}

__END__
Sum_{k=1..399} Sum_{d|k} ψ_0(d) = 7125
Sum_{k=1..898} Sum_{d|k} ψ_1(d) = 1005565
Sum_{k=1..284} Sum_{d|k} ψ_2(d) = 10904384
Sum_{k=1..363} Sum_{d|k} ψ_3(d) = 5089543732
Sum_{k=1..676} Sum_{d|k} ψ_4(d) = 30446345621064
Sum_{k=1..719} Sum_{d|k} ψ_5(d) = 23921678049099402
Sum_{k=1..273} Sum_{d|k} ψ_6(d) = 16623157368659789
Sum_{k=1..291} Sum_{d|k} ψ_7(d) = 6568878240105603914
Sum_{k=1..668} Sum_{d|k} ψ_8(d) = 2974535697414122138503228
Sum_{k=1..772} Sum_{d|k} ψ_9(d) = 7583168029177266313981257004
Sum_{k=1..967} Sum_{d|k} ψ_10(d) = 63269226338847691226388054366024
