#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 26 July 2017
# https://github.com/trizen

# Ramanujan's sum:
#   c_k(n) = Sum_{m mod k; gcd(m, k) = 1} exp(2*pi*i*m*n/k)

# For n = 1, c_k(1) is equivalent to moebius(k).

# For integer real values of `n` and `k`, Ramanujan's sum is equivalent to:
#   c_k(n) = Sum_{m mod k; gcd(m, k) = 1} cos(2*pi*m*n/k)

# Alternatively, when n = k, `c_n(n)` is equivalent with `euler_phi(n)`.

# The record values, `c_n(n) + 1`, are the prime numbers.

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(:overload tau gcd round);

sub ramanujan_sum {
    my ($n, $k) = @_;

    my $sum = 0;
    foreach my $m (1 .. $k) {
        if (gcd($m, $k) == 1) {
            $sum += exp(tau * i * $m * $n / $k);
        }
    }

    round($sum, -20);
}

my $sum = 0;
my @partial_sums;
foreach my $n (1 .. 30) {
    my $r = ramanujan_sum($n, $n**2);
    say "R($n, $n^2) = $r";
    push @partial_sums, $sum += $r;
}

say "\n=> Partial sums:";
say join(' ', @partial_sums);

__END__
R(1, 1^2) = 1
R(2, 2^2) = -2
R(3, 3^2) = -3
R(4, 4^2) = 0
R(5, 5^2) = -5
R(6, 6^2) = 6
R(7, 7^2) = -7
R(8, 8^2) = 0
R(9, 9^2) = 0
R(10, 10^2) = 10
R(11, 11^2) = -11
R(12, 12^2) = 0
R(13, 13^2) = -13
R(14, 14^2) = 14
R(15, 15^2) = 15
R(16, 16^2) = 0
R(17, 17^2) = -17
R(18, 18^2) = 0
R(19, 19^2) = -19
R(20, 20^2) = 0
R(21, 21^2) = 21
R(22, 22^2) = 22
R(23, 23^2) = -23
R(24, 24^2) = 0
R(25, 25^2) = 0
R(26, 26^2) = 26
R(27, 27^2) = 0
R(28, 28^2) = 0
R(29, 29^2) = -29
R(30, 30^2) = -30

=> Partial sums:
1 -1 -4 -4 -9 -3 -10 -10 -10 0 -11 -11 -24 -10 5 5 -12 -12 -31 -31 -10 12 -11 -11 -11 15 15 15 -14 -44
