#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 26 July 2017
# https://github.com/trizen

# Ramanujan's sum: c_k(n) = Sum_{m mod k; gcd(m, k) = 1} exp(2*pi*i*m*n/k).

# For n = 1, c_k(1) is equivalent to moebius(k).

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(i tau gcd round);

sub ramanujan_sum {
    my ($n, $k) = @_;

    my $sum = 0;
    foreach my $m (1 .. $k) {
        if (gcd($m, $k) == 1) {
            $sum += exp(tau * i * $m * $n / $k);
        }
    }

    round($sum);
}

my $sum = 0;
my @partial_sums;
foreach my $n (1 .. 30) {
    my $r = ramanujan_sum($n, $n);
    $sum += $r;
    say "R($n, $n) = $r";
    push @partial_sums, $sum;
}

say "\n=> Partial sums:";
say join(' ', @partial_sums);

__END__
R(1, 1) = 1
R(2, 2) = 1
R(3, 3) = 2
R(4, 4) = 2
R(5, 5) = 4
R(6, 6) = 2
R(7, 7) = 6
R(8, 8) = 4
R(9, 9) = 6
R(10, 10) = 4
R(11, 11) = 10
R(12, 12) = 4
R(13, 13) = 12
R(14, 14) = 6
R(15, 15) = 8
R(16, 16) = 8
R(17, 17) = 16
R(18, 18) = 6
R(19, 19) = 18
R(20, 20) = 8
R(21, 21) = 12
R(22, 22) = 10
R(23, 23) = 22
R(24, 24) = 8
R(25, 25) = 20
R(26, 26) = 12
R(27, 27) = 18
R(28, 28) = 12
R(29, 29) = 28
R(30, 30) = 8

=> Partial sums:
1 2 4 6 10 12 18 22 28 32 42 46 58 64 72 80 96 102 120 128 140 150 172 180 200 212 230 242 270 278
