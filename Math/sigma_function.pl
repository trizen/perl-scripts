#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 18 August 2017
# https://github.com/trizen

# Efficient implementation of the `sigma_k(n)` function, where k > 0.

use 5.010;
use strict;
use warnings;

use ntheory qw(factor_exp);

sub sigma {
    my ($n, $k) = @_;

    my $sigma = 1;

    foreach my $p (factor_exp($n)) {
        $sigma *= (($p->[0]**($k * ($p->[1] + 1)) - 1) / ($p->[0]**$k - 1));
    }

    return $sigma;
}

say sigma(10,      1);    #=> 18
say sigma(100,     1);    #=> 217
say sigma(3628800, 2);    #=> 20993420690550
