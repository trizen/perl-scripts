#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 16 November 2015
# Website: https://github.com/trizen

# zeta(s) = sum(1 / k^s)                        from k=1 to Infinity
# zeta(s) = product(1 / (1 - prime(k)^(-s)))    from k=1 to Infinity

use 5.010;
use strict;
use warnings;

use ntheory qw(nth_prime);

sub prime_zeta {
    my ($s) = @_;

    my $p = 1;
    for my $i (1 .. 10000) {
        $p *= 1 / (1 - 1 / nth_prime($i)**$s);
    }
    return $p;
}

say sqrt(prime_zeta(2) * 6);
