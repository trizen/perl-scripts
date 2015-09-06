#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 06 September 2015
# Website: https://github.com/trizen

# This script counts the numbers which CANNOT be written as sum of two primes

use 5.010;
use strict;
use warnings;

use ntheory qw(primes);

say "** Collecting...";
my $primes = primes(10000);

my %seen;
for my $i(0..$#{$primes}) {
    for my $j($i .. $#{$primes}) {
        $seen{$primes->[$i] + $primes->[$j]}++;
    }
}

say "** Counting...";

my $count = 0;
foreach my $n (1 .. 2*$primes->[-1]) {
   exists($seen{$n}) || ++$count;
}

say "\n$count numbers, from a total of ", 2*$primes->[-1], ", CANNOT be written as sum of two primes.\n";
