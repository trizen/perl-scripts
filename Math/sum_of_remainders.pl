#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 10 March 2021
# https://github.com/trizen

# Let's consider the following function:
#   a(n,v) = Sum_{k=1..n} (v mod k)

# The goal is to compute a(n,v) in sublinear time with respect to v.

# Formula:
#   a(n,v) = n*v - A024916(v) + Sum_{k=n+1..v} k*floor(v/k).

# Formula derived from:
#   a(n,v) = Sum_{k=1..n} (v - k*floor(v/k))
#          = n*v - Sum_{k=1..n} k*floor(v/k)
#          = n*v - Sum_{k=1..v} k*floor(v/k) + Sum_{k=n+1..v} k*floor(v/k)

# Related problem:
#   Is there a sublinear formula for computing: Sum_{1<=k<=n, gcd(k,n)=1} k*floor(n/k) ?

# See also:
#   https://oeis.org/A099726 -- Sum of remainders of the n-th prime mod k, for k = 1,2,3,...,n.
#   https://oeis.org/A340976 -- Sum_{1 < k < n} sigma(n) mod k, where sigma = A000203.
#   https://oeis.org/A340180 -- a(n) = Sum_{x in C(n)} (sigma(n) mod x), where C(n) is the set of numbers < n coprime to n, and sigma = A000203.

use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub triangular ($n) {    # Sum_{k=1..n} k = n-th triangular number
    divint(mulint($n, addint($n, 1)), 2);
}

sub sum_of_sigma ($n) {    # A024916(n) = Sum_{k=1..n} sigma(k) = Sum_{k=1..n} k*floor(n/k)

    my $T = 0;
    my $s = sqrtint($n);

    foreach my $k (1 .. $s) {
        my $t = divint($n, $k);
        $T = vecsum($T, triangular($t), mulint($k, $t));
    }

    subint($T, mulint(triangular($s), $s));
}

sub g ($a, $b) {    # g(a,b) = Sum_{k=a..b} k*floor(b/k)

    my $T = 0;

    while ($a <= $b) {

        my $t = divint($b, $a);
        my $u = divint($b, $t);

        $T = addint($T, mulint($t, subint(triangular($u), triangular(subint($a, 1)))));
        $a = addint($u, 1);
    }

    return $T;
}

sub sum_of_remainders ($n, $v) {    # sub-linear formula
    addint(subint(mulint($n, $v), sum_of_sigma($v)), g(addint($n, 1), $v));
}

say sprintf "[%s]", join(', ', map { sum_of_remainders($_,     nth_prime($_)) } 1 .. 20);      #=> A099726
say sprintf "[%s]", join(', ', map { sum_of_remainders($_ - 1, divisor_sum($_)) } 1 .. 20);    #=> A340976

foreach my $k (1 .. 8) {
    say("A099726(10^$k) = ", sum_of_remainders(powint(10, $k), nth_prime(powint(10, $k))));
}

__END__
A099726(10^1) = 30
A099726(10^2) = 2443
A099726(10^3) = 248372
A099726(10^4) = 25372801
A099726(10^5) = 2437160078
A099726(10^6) = 252670261459
A099726(10^7) = 24690625139657
A099726(10^8) = 2516604108737704
