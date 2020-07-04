#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 18 May 2017
# https://github.com/trizen

# A simple implementation of the sieve of Eratosthenes for prime numbers.

use 5.010;
use strict;
use warnings;

sub sieve_primes {
    my ($n) = @_;

    my @composite;
    foreach my $i (2 .. CORE::sqrt($n)) {
        if (!$composite[$i]) {
            for (my $j = $i**2 ; $j <= $n ; $j += $i) {
                $composite[$j] = 1;
            }
        }
    }

    my @primes;
    foreach my $p (2 .. $n) {
        $composite[$p] // push(@primes, $p);
    }

    return @primes;
}

my $n = shift(@ARGV) // 100;
my @primes = sieve_primes($n);
say join(' ', @primes);
say "PI($n) = ", scalar(@primes);
