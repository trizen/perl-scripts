#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 17 July 2016
# Website: https://github.com/trizen

# A new identity for e, based on (n+1)^n / n^n, as n->infinity,
# with the binomial expansion of (n+1)^n derived by the author.

#    n -> ∞
#     ---
#     \     binomial(n, k)
#     /    ---------------  =  e
#     ---      n^(n-k)
#    k = 0

use 5.014;
use strict;
use warnings;

use Math::BigNum qw(:constant);

my $n = 5000;         # the number of iterations - 1
my $sum = 0;

foreach my $k(0 .. $n) {
    $sum += $n->binomial($k) / $n**($n-$k);
}

say $sum;
