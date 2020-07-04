#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 26 February 2019
# https://github.com/trizen

# Given a positive integer n, find the smallest integer `k` such that `k*prime(k) > 10^n`.

# See also:
#   https://oeis.org/A090977 -- Least k such that k*prime(k) > 10^n.

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(:overload bsearch_ge);
use ntheory qw(nth_prime nth_prime_lower nth_prime_upper);

sub a {
    my ($n) = @_;

    my $lim = 10**$n;

    my $min_approx = int(sqrt($lim / log($lim+1)));
    my $max_approx = 2*$min_approx;

    my $min = bsearch_ge($min_approx, $max_approx, sub {
        nth_prime_upper($_) * $_ <=> $lim
    });

    my $max = bsearch_ge($min, $max_approx, sub {
        nth_prime_lower($_) * $_ <=> $lim
    });

    bsearch_ge($min, $max, sub {
        nth_prime($_) * $_ <=> $lim
    });
}

foreach my $n(0..22) {
    say "a($n) = ", a($n);
}

__END__
a(0) = 1
a(1) = 3
a(2) = 7
a(3) = 17
a(4) = 48
a(5) = 134
a(6) = 382
a(7) = 1115
a(8) = 3287
a(9) = 9786
a(10) = 29296
a(11) = 88181
a(12) = 266694
a(13) = 809599
a(14) = 2465574
a(15) = 7528976
a(16) = 23045352
a(17) = 70684657
a(18) = 217196605
a(19) = 668461874
a(20) = 2060257099
a(21) = 6358076827
a(22) = 19644205359
