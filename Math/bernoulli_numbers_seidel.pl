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

use Math::AnyNum;

sub bernoulli_seidel {
    my ($n) = @_;

    $n == 0 and return Math::AnyNum->one;
    $n == 1 and return Math::AnyNum->new('1/2');
    $n % 2  and return Math::AnyNum->zero;

    state $one = Math::GMPz::Rmpz_init_set_ui(1);

    my @D = (
             Math::GMPz::Rmpz_init_set_ui(0),
             Math::GMPz::Rmpz_init_set_ui(1),
             map { Math::GMPz::Rmpz_init_set_ui(0) } (1 .. $n / 2 - 1)
            );

    my ($h, $w) = (1, 1);
    foreach my $i (0 .. $n - 1) {
        if ($w ^= 1) {
            Math::GMPz::Rmpz_add($D[$_], $D[$_], $D[$_ - 1]) for (1 .. $h - 1);
        }
        else {
            $w = $h++;
            Math::GMPz::Rmpz_add($D[$w], $D[$w], $D[$w + 1]) while --$w;
        }
    }

    Math::AnyNum->new($D[$h - 1]) / Math::AnyNum->new((($one << ($n + 1)) - 2) * ($n % 4 == 0 ? -1 : 1));
}

foreach my $i (0 .. 50) {
    printf "B%-3d = %s\n", 2 * $i, bernoulli_seidel(2 * $i);
}
