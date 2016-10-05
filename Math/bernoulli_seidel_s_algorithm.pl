#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 06 October 2016
# Website: https://github.com/trizen

# Algorithm from:
#   http://oeis.org/wiki/User:Peter_Luschny/ComputationAndAsymptoticsOfBernoulliNumbers#Seidel

use 5.010;
use strict;
use warnings;

use Math::BigNum;

use constant {
              zero => Math::BigNum->zero,
              one  => Math::BigNum->one,
              half => Math::BigNum->new('1/2'),
             };

sub seidel_bernoulli {
    my ($n) = @_;

    $n == 0 and return one;
    $n == 1 and return half;
    $n % 2  and return zero;

    my @D = (zero) x ($n + 1);
    $D[1] = 1;

    my ($w, $h, $p) = (1, 1, one);

    foreach my $i (0 .. $n - 1) {
        if ($w) {
            $p *= 4;
            for (my $k = $h ; $k > 0 ; --$k) {
                $D[$k] += $D[$k + 1];
            }
            ++$h;
        }
        else {
            foreach my $k (1 .. $h - 1) {
                $D[$k] += $D[$k - 1];
            }
        }
        $w ^= 1;
    }
    $D[$h - 1] / (2 * ($p - 1) * ($n % 4 == 0 ? -1 : 1));
}

foreach my $i (0 .. 50) {
    printf "B%-3d = %s\n", 2 * $i, seidel_bernoulli(2 * $i)->as_rat;
}
