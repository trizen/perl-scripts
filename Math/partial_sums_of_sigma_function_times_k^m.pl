#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 10 November 2018
# https://github.com/trizen

# A new generalized algorithm with O(sqrt(n)) complexity for computing the partial-sums of `k^m * sigma_j(k)`, for `1 <= k <= n`:
#
#   Sum_{k=1..n} k^m * sigma_j(k)
#
# for any fixed m >= 0 and j >= 0.

# Formula:
#   Sum_{k=1..n} k^m * sigma_j(k) =   Sum_{k=1..floor(sqrt(n))} F(m, k) * (F(m+j, floor(n/k)) - F(m+j, floor(n/(k+1))))
#                                   + Sum_{k=1..floor(n/(floor(sqrt(n))+1))} k^(m+j) * F(m, floor(n/k))
#
# where F(n,x) is Faulhaber's formula for `Sum_{k=1..x} k^n`, defined in terms of Bernoulli polynomials as:
#
#   F(n, x) = (Bernoulli(n+1, x+1) - Bernoulli(n+1, 0)) / (n+1)
#
# and Bernoulli(n,x) are the Bernoulli polynomials.

# Example: `a(n) = Sum_{k=1..n} k^2 * sigma(k)`
#   a(10^1)  = 4948
#   a(10^2)  = 42206495
#   a(10^3)  = 412181273976
#   a(10^4)  = 4113599787351824
#   a(10^5)  = 41124390000844973548
#   a(10^6)  = 411234935063990235195050
#   a(10^7)  = 4112336345692801578349555781
#   a(10^8)  = 41123352884070223300364205949432
#   a(10^9)  = 411233517733637365707365200123054947
#   a(10^10) = 4112335168452793891288471658633554668746

# Asymptotic formulas:
#   a(10^k) ~ Pi^2/24 * 10^(4*k)
#   a(10^k) ~ zeta(2)/4 * 10^(4*k)

# Extra:
#   zeta(3)/5 * 10^(5*k) ~ Sum_{k=1..10^n} k^2 * sigma_2(k)

# See also:
#   https://en.wikipedia.org/wiki/Divisor_function
#   https://en.wikipedia.org/wiki/Faulhaber%27s_formula
#   https://en.wikipedia.org/wiki/Bernoulli_polynomials
#   https://trizenx.blogspot.com/2018/08/interesting-formulas-and-exercises-in.html

use 5.020;
use strict;
use warnings;

use ntheory qw(divisor_sum);
use experimental qw(signatures);
use Math::AnyNum qw(faulhaber_sum isqrt ipow sum);

sub fast_sigma_partial_sum($n, $m, $j) {      # O(sqrt(n)) complexity

    my $total = 0;

    my $s = isqrt($n);
    my $u = int($n / ($s + 1));

    for my $k (1 .. $s) {
        $total += faulhaber_sum($k, $m) * (faulhaber_sum(int($n/$k), $m+$j) - faulhaber_sum(int($n/($k+1)), $m+$j));
    }

    for my $k (1 .. $u) {
        $total += ipow($k, $m+$j) * faulhaber_sum(int($n/$k), $m);
    }

    return $total;

}

sub sigma_partial_sum($n, $m, $j) {           # just for testing
    sum(map { ipow($_, $m) * divisor_sum($_, $j) } 1..$n);
}

for my $m (0..10) {

    my $j = int rand 10;
    my $n = int rand 1000;

    my $t1 = sigma_partial_sum($n, $m, $j);
    my $t2 = fast_sigma_partial_sum($n, $m, $j);

    die "error: $t1 != $t2" if ($t1 != $t2);

    say "Sum_{k=1..$n} k^$m * σ_$j(k) = $t2";
}

__END__
Sum_{k=1..955} k^0 * σ_7(k) = 87199595877187457268469
Sum_{k=1..765} k^1 * σ_5(k) = 22385163976024509818
Sum_{k=1..805} k^2 * σ_6(k) = 15993292528868648475167542
Sum_{k=1..477} k^3 * σ_2(k) = 2374273670858643
Sum_{k=1..522} k^4 * σ_8(k) = 16674413261032779166355164886215351
Sum_{k=1..983} k^5 * σ_0(k) = 1180528862233337314
Sum_{k=1..293} k^6 * σ_1(k) = 11217015502565855041
Sum_{k=1..906} k^7 * σ_7(k) = 15353361004402823613827018815424339863159897
Sum_{k=1..467} k^8 * σ_2(k) = 25400023350505369496677066803
Sum_{k=1..801} k^9 * σ_4(k) = 3343390385697199861864437708422750691782
Sum_{k=1..142} k^10 * σ_8(k) = 4409116061384423423777822848241899183830
