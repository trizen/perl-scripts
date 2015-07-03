#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 03 July 2015
# Website: https://github.com/trizen

# Generate a top list of prime formulas (in the form of: n^2 - n ± m)

use 5.010;
use strict;
use warnings;

use ntheory qw(is_prime);

my %top;
my $n_limit = 1e4;
my $m_limit = 1e2;

foreach my $m (1 .. $m_limit) {

    next if $m % 2 == 0;

    foreach my $n (0 .. $n_limit) {

        my $n1 = $n**2 - $n + $m;
        my $n2 = $n**2 - $n - $m;

        if ($n1 > 1 and is_prime($n1)) {
            ++$top{$m};
        }

        if ($n2 > 1 and is_prime($n2)) {
            ++$top{-$m};
        }
    }
}

foreach my $key (sort { $top{$b} <=> $top{$a} } keys %top) {
    printf("[%5d] n^2 - n %s %s\n", $top{$key}, $key > 0 ? ('+', $key) : ('-', abs($key)));
}
