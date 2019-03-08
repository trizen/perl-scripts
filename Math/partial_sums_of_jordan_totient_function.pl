#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 21 November 2018
# https://github.com/trizen

# A new algorithm for computing the partial-sums of the Jordan totient function `J_m(k)`, for `1 <= k <= n`:
#
#   Sum_{k=1..n} J_m(k)
#
# for any fixed integer m >= 1.

# Based on the formula:
#   Sum_{k=1..n} J_m(k) = Sum_{k=1..n} moebius(k) * F(m, floor(n/k))
#
# where F(n,x) is Faulhaber's formula for `Sum_{k=1..x} k^n`, defined in terms of Bernoulli polynomials as:
#   F(n, x) = (Bernoulli(n+1, x+1) - Bernoulli(n+1, 1)) / (n+1)

# Example for a(n) = Sum_{k=1..n} J_2(k):
#  a(10^1) = 312
#  a(10^2) = 280608
#  a(10^3) = 277652904
#  a(10^4) = 277335915120
#  a(10^5) = 277305865353048
#  a(10^6) = 277302780859485648
#  a(10^7) = 277302491422450102032
#  a(10^8) = 277302460845902192282712
#  a(10^9) = 277302457878113251222146576

# Asymptotic formula:
#   Sum_{k=1..n} J_2(k) ~ n^3 / (3*zeta(3))

# In general, for m>=1:
#   Sum_{k=1..n} J_m(k) ~ n^(m+1) / ((m+1) * zeta(m+1))

# See also:
#   https://oeis.org/A321879
#   https://en.wikipedia.org/wiki/Mertens_function
#   https://en.wikipedia.org/wiki/M%C3%B6bius_function
#   https://en.wikipedia.org/wiki/Jordan%27s_totient_function
#   https://trizenx.blogspot.com/2018/11/partial-sums-of-arithmetical-functions.html

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(faulhaber_sum ipow);
use ntheory qw(jordan_totient moebius mertens vecsum sqrtint forsquarefree is_square_free);

sub jordan_totient_partial_sum ($n, $m) {

    my $total = 0;

    my $s = sqrtint($n);
    my $u = int($n / ($s + 1));

    my $prev = mertens($n);

    for my $k (1 .. $s) {
        my $curr = mertens(int($n / ($k + 1)));
        $total += ($prev - $curr) * faulhaber_sum($k, $m);
        $prev = $curr;
    }

    forsquarefree {
        $total += moebius($_) * faulhaber_sum(int($n / $_), $m);
    } $u;

    return $total;
}

sub jordan_totient_partial_sum_2 ($n, $m) {

    my $total = 0;
    my $s = sqrtint($n);

    for my $k (1 .. $s) {
        $total += ipow($k, $m) * mertens(int($n/$k));
        $total += moebius($k) * faulhaber_sum(int($n/$k), $m) if is_square_free($k);
    }

    $total -= faulhaber_sum($s, $m) * mertens($s);

    return $total;
}

sub jordan_totient_partial_sum_test ($n, $m) {    # just for testing
    vecsum(map { jordan_totient($m, $_) } 1 .. $n);
}

for my $m (0 .. 10) {

    my $n = int rand 10000;

    my $t1 = jordan_totient_partial_sum($n, $m);
    my $t2 = jordan_totient_partial_sum_2($n, $m);
    my $t3 = jordan_totient_partial_sum_test($n, $m);

    die "error: $t1 != $t2" if ($t1 != $t2);
    die "error: $t1 != $t3" if ($t1 != $t3);

    say "Sum_{k=1..$n} J_$m(k) = $t1";
}

__END__
Sum_{k=1..3244} J_0(k) = 1
Sum_{k=1..5688} J_1(k) = 9834896
Sum_{k=1..9961} J_2(k) = 274117576704
Sum_{k=1..2548} J_3(k) = 9743111756724
Sum_{k=1..1147} J_4(k) = 383774380194000
Sum_{k=1..9985} J_5(k) = 162406071542610636006836
Sum_{k=1..8677} J_6(k) = 524873561219508820442845176
Sum_{k=1..3594} J_7(k) = 3469354096873688451827581144
Sum_{k=1..6424} J_8(k) = 2067471378951107437291216947429120
Sum_{k=1..5169} J_9(k) = 1361614000750853225756775763744598788
Sum_{k=1..7785} J_10(k) = 578821237542299170578127992588067328813064
