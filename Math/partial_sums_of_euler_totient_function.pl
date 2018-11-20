#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 20 Novermber 2018
# https://github.com/trizen

# A new algorithm for computing the partial-sums of `ϕ(k)`, for `1 <= k <= n`:
#
#   Sum_{k=1..n} phi(k)
#
# where phi(k) is the Euler totient function.

# Based on the formula:
#   Sum_{k=1..n} phi(k) = (1/2)*Sum_{k=1..n} moebius(k) * floor(n/k) * floor(1+n/k)

# Example:
#   a(10^1) = 32
#   a(10^2) = 3044
#   a(10^3) = 304192
#   a(10^4) = 30397486
#   a(10^5) = 3039650754
#   a(10^6) = 303963552392
#   a(10^7) = 30396356427242
#   a(10^8) = 3039635516365908
#   a(10^9) = 303963551173008414

# This algorithm can be improved.

# See also:
#   https://oeis.org/A002088
#   https://oeis.org/A064018
#   https://en.wikipedia.org/wiki/Mertens_function
#   https://en.wikipedia.org/wiki/M%C3%B6bius_function
#   https://en.wikipedia.org/wiki/Euler%27s_totient_function
#   https://trizenx.blogspot.com/2018/08/interesting-formulas-and-exercises-in.html

use 5.020;
use strict;
use warnings;

use Math::GMPz qw();
use experimental qw(signatures);
use ntheory qw(euler_phi moebius mertens vecsum sqrtint);

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

    for my $k (1 .. $u) {
        if (my $m = moebius($k)) {
            my $t = int($n / $k);
            $total += $m * $t * ($t + 1);
        }
    }

    return $total / 2;
}

sub euler_totient_partial_sum_test ($n) {    # just for testing
    vecsum(map { euler_phi($_) } 1 .. $n);
}

for my $m (0 .. 10) {

    my $n = int rand 10000;

    my $t1 = euler_totient_partial_sum($n);
    my $t2 = euler_totient_partial_sum_test($n);

    die "error: $t1 != $t2" if ($t1 != $t2);

    say "Sum_{k=1..$n} phi(k) = $t1";
}

__END__
Sum_{k=1..9321} phi(k) = 26411174
Sum_{k=1..2266} phi(k) = 1560824
Sum_{k=1..1049} phi(k) = 335018
Sum_{k=1..2571} phi(k) = 2009942
Sum_{k=1..3858} phi(k) = 4524786
Sum_{k=1..7348} phi(k) = 16412608
Sum_{k=1..7177} phi(k) = 15659862
Sum_{k=1..1247} phi(k) = 473174
Sum_{k=1..9787} phi(k) = 29119732
Sum_{k=1..4790} phi(k) = 6975570
Sum_{k=1..2453} phi(k) = 1830240
