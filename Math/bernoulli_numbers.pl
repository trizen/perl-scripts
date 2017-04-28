#!/usr/bin/perl

# Akiyama–Tanigawa algorithm for computing the nth-Bernoulli number.

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(:overload);

# Translation of:
#   https://en.wikipedia.org/wiki/Bernoulli_number#Algorithmic_description

sub bernoulli {
    my ($n) = @_;

    return 0 if $n > 1 && $n % 2;    # Bn = 0 for all odd n > 1

    my @A;
    for my $m (0 .. $n) {
        $A[$m] = 1 / ($m + 1);

        for (my $j = $m ; $j > 0 ; $j--) {
            $A[$j - 1] = $j * ($A[$j - 1] - $A[$j]);
        }
    }

    return $A[0];                    # which is Bn
}

foreach my $i (0 .. 50) {
    printf "B%-3d = %s\n", 2 * $i, bernoulli(2 * $i);
}
