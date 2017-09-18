#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 20 August 2015
# Website: https://github.com/trizen

# This script counts the numbers which CANNOT be written as the sum of two primes

use 5.010;
use strict;
use warnings;

use ntheory qw(primes);

my $primes = primes(10000);
unshift @{$primes}, 1;    # consider 1 as being prime

my %seen;
for my $i (0 .. $#{$primes}) {
    for my $j ($i .. $#{$primes}) {
        undef $seen{$primes->[$i] + $primes->[$j]};
    }
}

my $count = 0;
foreach my $n (1 .. 2 * $primes->[-1]) {
    exists($seen{$n}) || ++$count;
}

say "$count numbers, from a total of ", 2 * $primes->[-1], ", CANNOT be written as the sum of two primes.";

__END__
8772 numbers, from a total of 19946, CANNOT be written as the sum of two primes.
