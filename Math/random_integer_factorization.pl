#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 19 May 2017
# https://github.com/trizen

# A very simple random integer factorization algorithm.

use 5.010;
use strict;
use warnings;

use ntheory qw(random_prime);

my $n = 1355533 * 3672541;
my $r = int(sqrt($n));

my $x = $r;
my $y = $r;

while (1) {
    my $p = $x * $y;

    last if $p == $n;

    $x = random_prime(2, $r);
    $y = int($n / $x);
}

say "$n = $x * $y";
