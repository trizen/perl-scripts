#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 22 November 2018
# https://github.com/trizen

# A new algorithm for computing the partial-sums of the Dedekind psi function `ψ_m(k)`, for `1 <= k <= n`:
#
#   Sum_{k=1..n} ψ_m(k)
#
# for any fixed integer m >= 1.

# Based on the formula:
#   Sum_{k=1..n} ψ_m(k) = Sum_{k=1..n} moebius(k)^2 * F(m, floor(n/k))
#
# where F(n,x) is Faulhaber's formula for `Sum_{k=1..x} k^n`, defined in terms of Bernoulli polynomials as:
#   F(n, x) = (Bernoulli(n+1, x+1) - Bernoulli(n+1, 1)) / (n+1)

# Example for a(n) = Sum_{k=1..n} ψ_2(k):
#   a(10^1)  = 462
#   a(10^2)  = 400576
#   a(10^3)  = 394504950
#   a(10^4)  = 393921912410
#   a(10^5)  = 393861539651230
#   a(10^6)  = 393855661025817568
#   a(10^7)  = 393855049001462029696
#   a(10^8)  = 393854989687473892017612
#   a(10^9)  = 393854983651633712634417940
#   a(10^10) = 393854983070527507612754907046

# For m=1..3, we have the following asymptotic formulas:
#   Sum_{k=1..n} ψ_1(k) ~ n^2 * zeta(2) / (2*zeta(4))
#   Sum_{k=1..n} ψ_2(k) ~ n^3 * zeta(3) / (3*zeta(6))
#   Sum_{k=1..n} ψ_3(k) ~ n^4 * zeta(4) / (4*zeta(8))

# In general, for m>=1, we have:
#   Sum_{k=1..n} ψ_m(k) ~ n^(m+1) * zeta(m+1) / ((m+1) * zeta(2*(m+1)))

# See also:
#   https://oeis.org/A173290
#   https://en.wikipedia.org/wiki/M%C3%B6bius_function
#   https://en.wikipedia.org/wiki/Dedekind_psi_function
#   https://trizenx.blogspot.com/2018/11/partial-sums-of-arithmetical-functions.html

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(ipow faulhaber_sum);
use ntheory qw(jordan_totient moebius vecsum sqrtint forsquarefree is_square_free);

sub squarefree_count {
    my ($n) = @_;

    my $k     = 0;
    my $count = 0;

    foreach my $m (moebius(1, sqrtint($n))) {
        ++$k; $count += $m * int($n / $k / $k);
    }

    return $count;
}

sub dedekind_psi_partial_sum ($n, $m) {     # O(sqrt(n)) complexity

    my $total = 0;

    my $s = sqrtint($n);
    my $u = int($n / ($s + 1));

    my $prev = squarefree_count($n);

    for my $k (1 .. $s) {
        my $curr = squarefree_count(int($n / ($k + 1)));
        $total += ($prev - $curr) * faulhaber_sum($k, $m);
        $prev = $curr;
    }

    forsquarefree {
        $total += faulhaber_sum(int($n / $_), $m);
    } $u;

    return $total;
}

sub dedekind_psi_partial_sum_2 ($n, $m) {     # O(sqrt(n)) complexity

    my $total = 0;
    my $s = sqrtint($n);

    for my $k (1 .. $s) {
        $total += ipow($k, $m) * squarefree_count(int($n/$k));
        $total += faulhaber_sum(int($n/$k), $m) if is_square_free($k);
    }

    $total -= squarefree_count($s) * faulhaber_sum($s, $m);

    return $total;
}

sub dedekind_psi_partial_sum_test ($n, $m) {    # just for testing
    vecsum(map { jordan_totient(2*$m, $_) / jordan_totient($m, $_) } 1 .. $n);
}

for my $m (1 .. 10) {

    my $n = int rand 1000;

    my $t1 = dedekind_psi_partial_sum($n, $m);
    my $t2 = dedekind_psi_partial_sum_2($n, $m);
    my $t3 = dedekind_psi_partial_sum_test($n, $m);

    die "error: $t1 != $t2" if ($t1 != $t2);
    die "error: $t1 != $t3" if ($t1 != $t3);

    say "Sum_{k=1..$n} psi_$m(k) = $t1";
}

__END__
Sum_{k=1..626} psi_1(k) = 298020
Sum_{k=1..203} psi_2(k) = 3314412
Sum_{k=1..527} psi_3(k) = 20858324486
Sum_{k=1..912} psi_4(k) = 131086192304600
Sum_{k=1..221} psi_5(k) = 20014030184914
Sum_{k=1..980} psi_6(k) = 125495875567427222916
Sum_{k=1..892} psi_7(k) = 50529225624273249380976
Sum_{k=1..831} psi_8(k) = 21153451972416324344508126
Sum_{k=1..384} psi_9(k) = 7069511971715257063270976
Sum_{k=1..434} psi_10(k) = 9477667039001209551910807864
