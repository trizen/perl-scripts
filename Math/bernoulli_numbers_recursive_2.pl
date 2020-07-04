#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 04 October 2016
# Website: https://github.com/trizen

# Recursive computation of Bernoulli numbers (slightly improved).
# https://en.wikipedia.org/wiki/Bernoulli_number#Recursive_definition

use 5.014;
use strict;
use warnings;

use Memoize qw(memoize);
use Math::AnyNum qw(:overload binomial);

memoize('bernoulli');

sub bernoulli {
    my ($n) = @_;

    return 1/2 if $n == '1';
    return   0 if $n  % '2';
    return   1 if $n == '0';

    my $bern = 1/2 - 1 / ($n + 1);
    for (my $k = '2' ; $k < $n ; $k += '2') {
        $bern -= bernoulli($k) * binomial($n, $k) / ($n - $k + '1');
    }
    $bern;
}

foreach my $i (0 .. 50) {
    printf "B%-3d = %s\n", '2' * $i, bernoulli('2' * $i);
}
