#!/usr/bin/perl

# Author: Trizen
# License: GPLv3
# Date: 20th November 2013
# http://trizenx.blogspot.com

# Prime numbers with difference of two
# are grouped together if have a given difference
# related to other numbers.

# Example: 17, 19 and 59, 61 (diff == 42)

use 5.010;
use strict;
use warnings;

use Data::Dump qw(pp);
use ntheory qw(is_prime);

my @primes = grep { is_prime($_) } 0 .. 1000;

my @twin_primes;
foreach my $i (0 .. $#primes) {
    foreach my $j ($i + 1 .. $#primes) {
        my $diff = $primes[$j] - $primes[$i];
        if ($diff == 2) {
            push @twin_primes, [$primes[$i], $primes[$j]];
        }
        elsif ($diff > 2) {
            last;
        }
    }
}

my %table;
foreach my $i (0 .. $#twin_primes) {
    foreach my $j ($i + 1 .. $#twin_primes) {
        my $diff = $twin_primes[$j][0] - $twin_primes[$i][0];
        push @{$table{$diff}}, [[@{$twin_primes[$i]}], [@{$twin_primes[$j]}]];
    }
}

my @max = (sort { $#{$table{$b}} <=> $#{$table{$a}} } keys %table);

# Top 10
foreach my $i (0 .. 9) {
    say "$max[$i]: ", pp($table{$max[$i]});
}
