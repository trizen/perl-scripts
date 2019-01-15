#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 15 January 2019
# https://github.com/trizen

# Efficient program for computing the sum of exponents in prime-power factorization of n!.

#~ a(10^1)  = 15
#~ a(10^2)  = 239
#~ a(10^3)  = 2877
#~ a(10^4)  = 31985
#~ a(10^5)  = 343614
#~ a(10^6)  = 3626619
#~ a(10^7)  = 37861249
#~ a(10^8)  = 392351272
#~ a(10^9)  = 4044220058
#~ a(10^10) = 41518796555

# See also:
#   https://oeis.org/A022559
#   https://oeis.org/A071811

use 5.014;
use strict;
use warnings;

use ntheory qw(vecsum logint sqrtint rootint prime_count forprimes);

sub prime_power_count {
    my ($n) = @_;
    vecsum(map { prime_count(rootint($n, $_)) } 1 .. logint($n, 2));
}

sub sum_of_exponents_of_factorial {
    my ($n) = @_;

    return 0 if ($n <= 1);

    my $s = sqrtint($n);
    my $u = int($n / ($s + 1));

    my $total = 0;
    my $prev  = prime_power_count($n);

    for my $k (1 .. $s) {
        my $curr = prime_power_count(int($n / ($k + 1)));
        $total += $k * ($prev - $curr);
        $prev = $curr;
    }

    forprimes {
        foreach my $k (1 .. logint($u, $_)) {
            $total += int($n / $_**$k);
        }
    }
    $u;

    return $total;
}

foreach my $k (1 .. 10) {
    say "a(10^$k) = ", sum_of_exponents_of_factorial(10**$k);
}
