#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 20 November 2018
# https://github.com/trizen

# A new algorithm for computing the partial-sums of the gcd-sum function `Sum_{d|k} d*ϕ(k/d)`, for `1 <= k <= n`:
#
#   a(n) = Sum_{k=1..n} Sum_{d|k} d*phi(k/d)
#
# where phi(k) is the Euler totient function.

# Also equivalent with:
#   a(n) = Sum_{j=1..n} Sum_{i=1..j} gcd(i, j)

# Based on the formula:
#   a(n) = (1/2)*Sum_{k=1..n} phi(k) * floor(n/k) * floor(1+n/k)

# Example:
#   a(10^1) = 122
#   a(10^2) = 18065
#   a(10^3) = 2475190
#   a(10^4) = 317257140
#   a(10^5) = 38717197452
#   a(10^6) = 4571629173912
#   a(10^7) = 527148712519016
#   a(10^8) = 59713873168012716
#   a(10^9) = 6671288261316915052

# This algorithm can be vastly improved.

# See also:
#   https://oeis.org/A018804
#   https://oeis.org/A272718
#   https://en.wikipedia.org/wiki/Mertens_function
#   https://en.wikipedia.org/wiki/M%C3%B6bius_function
#   https://en.wikipedia.org/wiki/Euler%27s_totient_function
#   https://trizenx.blogspot.com/2018/11/partial-sums-of-arithmetical-functions.html

use 5.020;
use strict;
use warnings;

use Math::GMPz qw();
use experimental qw(signatures);
use ntheory qw(euler_phi moebius mertens sqrtint forsquarefree);

sub euler_totient_partial_sum ($n) {

    my $total = Math::GMPz->new(0);

    my $s = sqrtint($n);
    my $u = int($n / ($s + 1));

    my $prev = mertens($n);

    for my $k (1 .. $s) {
        my $curr = mertens(int($n / ($k + 1)));
        $total += ($prev - $curr) * $k * ($k + 1);
        $prev = $curr;
    }

    forsquarefree {
        my $t = int($n / $_);
        $total += moebius($_) * $t * ($t + 1);
    } $u;

    return $total / 2;
}

sub gcd_sum_partial_sum($n) {

    my $total = Math::GMPz->new(0);

    my $s = sqrtint($n);
    my $u = int($n / ($s + 1));

    my $prev = euler_totient_partial_sum($n);

    for my $k (1 .. $s) {
        my $curr = euler_totient_partial_sum(int($n / ($k + 1)));
        $total += ($prev - $curr) * $k * ($k + 1);
        $prev = $curr;
    }

    for my $k (1 .. $u) {
        my $t = int($n / $k);
        $total += euler_phi($k) * $t * ($t + 1);
    }

    return $total / 2;
}

sub gcd_sum_partial_sum_test ($n) {    # just for testing
    my $sum = Math::GMPz->new(0);

    foreach my $k (1 .. $n) {
        my $t = int($n / $k);
        $sum += euler_phi($k) * $t * ($t + 1);
    }

    return $sum / 2;
}

for my $m (0 .. 10) {

    my $n = int rand 10000;

    my $t1 = gcd_sum_partial_sum($n);
    my $t2 = gcd_sum_partial_sum_test($n);

    die "error: $t1 != $t2" if ($t1 != $t2);

    say "Sum_{k=1..$n} G(k) = $t1";
}

__END__
Sum_{k=1..6249} G(k) = 118276019
Sum_{k=1..6470} G(k) = 127257585
Sum_{k=1..1271} G(k) = 4109678
Sum_{k=1..4849} G(k) = 69427261
Sum_{k=1..6771} G(k) = 140029473
Sum_{k=1..5078} G(k) = 76492429
Sum_{k=1..1262} G(k) = 4054055
Sum_{k=1..7751} G(k) = 185959182
Sum_{k=1..4188} G(k) = 51033167
Sum_{k=1..5283} G(k) = 83132565
Sum_{k=1..2574} G(k) = 18289119
