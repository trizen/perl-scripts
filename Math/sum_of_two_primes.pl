#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 20 August 2015
# Website: https://github.com/trizen

# This script shows the numbers which can be written as the sum of two primes

## Example:
# 2 + 2 = 4
# 3 + 2 = 5
# 3 + 3 = 6

use 5.010;
use strict;
use warnings;

use ntheory qw(primes factor is_prime);

my $primes = primes(100);

my %seen;
foreach my $p1 (@{$primes}) {
    foreach my $p2 (@{$primes}) {
        $seen{$p1 + $p2}++;
    }
}

my $count = 0;
foreach my $n (2 .. $primes->[-1]) {
    if (not exists $seen{$n}) {
        if (is_prime($n)) {
            say $n;
        }
        else {
            say $n, ' (', join(' * ', factor($n)), ')';
        }
        ++$count;
    }
}

say "\nOnly $count numbers, from a total of ", $primes->[-1], ", cannot be written as sum of two primes.\n";
