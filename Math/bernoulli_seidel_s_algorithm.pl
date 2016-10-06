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

sub bernoulli_seidel {
    my ($n) = @_;

    $n == 0 and return Math::BigNum->one;
    $n == 1 and return Math::BigNum->new('1/2');
    $n %  2 and return Math::BigNum->zero;

    state $zero = Math::GMPz->new(0);
    state $one  = Math::GMPz->new(1);

    my @D = ($zero, $one, ($zero) x ($n - 1));

    my ($h, $w) = (1, 1);
    foreach my $i (0 .. $n - 1) {
        if ($w ^= 1) {
            $D[$_] += $D[$_ - 1] for (1 .. $h - 1);
        }
        else {
            $w = $h++;
            $D[$w] += $D[$w + 1] while --$w;
        }
    }

    Math::BigNum->new($D[$h - 1]) / Math::BigNum->new((($one << ($n + 1)) - 2) * ($n % 4 == 0 ? -1 : 1));
}

foreach my $i (0 .. 50) {
    printf "B%-3d = %s\n", 2 * $i, bernoulli_seidel(2 * $i)->as_rat;
}
