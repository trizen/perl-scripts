#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 29 September 2017
# https://github.com/trizen

# Compute `binomial(n, k) % m`, using the `factorialmod(n, m)` function from ntheory.

use 5.010;
use strict;
use warnings;

use ntheory qw(divmod factorialmod);

sub modular_binomial {
    my ($n, $k, $m) = @_;
    divmod(divmod(factorialmod($n, $m), factorialmod($k, $m), $m), factorialmod($n - $k, $m), $m);
}

say modular_binomial(100, 50, 139);        #=> 71
say modular_binomial(124, 42, 1234567);    #=> 395154
