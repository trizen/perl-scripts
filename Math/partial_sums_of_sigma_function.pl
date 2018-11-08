#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 09 November 2018
# https://github.com/trizen

# A new generalized algorithm with O(sqrt(n)) complexity for computing the partial-sums of the `sigma_j(k)` function:
#
#   Sum_{k=1..n} sigma_j(k)
#
# for any j >= 0.

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
use Math::AnyNum qw(faulhaber_sum bernoulli sum isqrt ipow);

sub faulhaber_partial_sum_of_sigma ($n, $m = 1) {       # using Faulhaber's formula

    my $s = isqrt($n);
    my $u = int($n / ($s + 1));

    my $sum = 0;

    foreach my $k (1 .. $s) {
        $sum += $k * (faulhaber_sum(int($n/$k), $m) - faulhaber_sum(int($n/($k+1)), $m));
    }

    foreach my $k (1 .. $u) {
        $sum += ipow($k, $m) * int($n / $k);
    }

    return $sum;
}

sub bernoulli_partial_sum_of_sigma ($n, $m = 1) {       # using Bernoulli polynomials

    my $s = isqrt($n);
    my $u = int($n / ($s + 1));

    my $sum = 0;

    foreach my $k (1 .. $s) {
        $sum += $k * (bernoulli($m+1, 1+int($n/$k)) - bernoulli($m+1, 1+int($n/($k+1)))) / ($m+1);
    }

    foreach my $k (1 .. $u) {
        $sum += ipow($k, $m) * int($n / $k);
    }

    return $sum;
}

sub partial_sum_of_sigma ($n, $m = 1) {    # just for testing
    sum(map { sum(map { ipow($_, $m) } divisors($_)) } 1..$n);
}

foreach my $m (0 .. 10) {

    my $n = int(rand(1000));

    my $t1 = partial_sum_of_sigma($n, $m);
    my $t2 = faulhaber_partial_sum_of_sigma($n, $m);
    my $t3 = bernoulli_partial_sum_of_sigma($n, $m);

    say "Sum_{k=1..$n} sigma_$m(k) = $t2";

    die "error: $t1 != $t2" if ($t1 != $t2);
    die "error: $t1 != $t3" if ($t1 != $t3);
}

__END__
Sum_{k=1..198} sigma_0(k) = 1084
Sum_{k=1..657} sigma_1(k) = 355131
Sum_{k=1..933} sigma_2(k) = 325914283
Sum_{k=1..905} sigma_3(k) = 181878297343
Sum_{k=1..402} sigma_4(k) = 2191328841200
Sum_{k=1..967} sigma_5(k) = 139059243381760868
Sum_{k=1..320} sigma_6(k) = 50042081613053611
Sum_{k=1..168} sigma_7(k) = 81561359789498529
Sum_{k=1..977} sigma_8(k) = 90713993807165413835362083
Sum_{k=1..219} sigma_9(k) = 25985664184393953943010
Sum_{k=1..552} sigma_10(k) = 133190310787744370768676943091
