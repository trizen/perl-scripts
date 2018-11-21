#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 10 November 2018
# https://github.com/trizen

# A new generalized algorithm with O(sqrt(n)) complexity for computing the partial-sums of `k * sigma_j(k)`, for `1 <= k <= n`:
#
#   Sum_{k=1..n} k * sigma_j(k)
#
# for any fixed j >= 0.

# Example: `a(n) = Sum_{k=1..n} k * sigma(k)`
#   a(10^1)  = 622
#   a(10^2)  = 558275
#   a(10^3)  = 549175530
#   a(10^4)  = 548429473046
#   a(10^5)  = 548320905633448
#   a(10^6)  = 548312690631798482
#   a(10^7)  = 548311465139943768941
#   a(10^8)  = 548311366911386862908968
#   a(10^9)  = 548311356554322895313137239
#   a(10^10) = 548311355740964925044531454428

# For m>=0 and j>=1, we have the following asymptotic formula:
#   Sum_{k=1..n} k^m * sigma_j(k) ~ zeta(j+1)/(j+m+1) * n^(j+m+1)

# See also:
#   https://en.wikipedia.org/wiki/Divisor_function
#   https://en.wikipedia.org/wiki/Faulhaber%27s_formula
#   https://en.wikipedia.org/wiki/Bernoulli_polynomials
#   https://trizenx.blogspot.com/2018/08/interesting-formulas-and-exercises-in.html

use 5.020;
use strict;
use warnings;

use ntheory qw(divisors);
use experimental qw(signatures);
use Math::AnyNum qw(faulhaber_sum sum isqrt ipow);

sub fast_sigma_partial_sum($n, $m) {       # O(sqrt(n)) complexity

    my $total = 0;

    my $s = isqrt($n);
    my $u = int($n / ($s + 1));

    for my $k (1 .. $s) {
        $total += $k*($k+1) * (faulhaber_sum(int($n/$k), $m+1) - faulhaber_sum(int($n/($k+1)), $m+1));
    }

    for my $k (1 .. $u) {
        $total += ipow($k, $m+1) * int($n/$k) * (1 + int($n/$k));
    }

    return $total/2;
}

sub sigma_partial_sum($n, $m) {      # just for testing
    sum(map { $_ * sum(map { ipow($_, $m) } divisors($_)) } 1..$n);
}

for my $m (0..10) {

    my $n = int(rand(1000));

    my $t1 = sigma_partial_sum($n, $m);
    my $t2 = fast_sigma_partial_sum($n, $m);

    die "error: $t1 != $t2" if ($t1 != $t2);

    say "Sum_{k=1..$n} k * σ_$m(k) = $t2"
}

__END__
Sum_{k=1..649} k * σ_0(k) = 1505437
Sum_{k=1..184} k * σ_1(k) = 3442689
Sum_{k=1..156} k * σ_2(k) = 180861250
Sum_{k=1..781} k * σ_3(k) = 63090289257686
Sum_{k=1..822} k * σ_4(k) = 53514505511600484
Sum_{k=1..982} k * σ_5(k) = 128445772086331164364
Sum_{k=1..742} k * σ_6(k) = 11644176895188820029668
Sum_{k=1..837} k * σ_7(k) = 22614022054863154308526282
Sum_{k=1..355} k * σ_8(k) = 3230297764819153302018985
Sum_{k=1..837} k * σ_9(k) = 12937980446016909148074821860258
Sum_{k=1..699} k * σ_10(k) = 1144140317656849776081892799180303
