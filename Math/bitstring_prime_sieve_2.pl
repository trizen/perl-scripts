#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 14 May 2018
# https://github.com/trizen

# A decently fast bit-string sieve for prime numbers.

# Useful when memory is very restricted.

use 5.010;
use strict;
use warnings;

sub bitstring_prime_sieve {
    my ($n) = @_;

    my $c     = '';
    my $bound = int(sqrt($n));

    for (my $i = 3 ; $i <= $bound ; $i += 2) {
        if (!vec($c, $i, 1)) {
            for (my $j = $i * $i ; $j <= $n ; $j += $i << 1) {
                vec($c, $j, 1) = 1;
            }
        }
    }

    my @primes = (2);
    foreach my $k (1 .. ($n - 1) >> 1) {
        vec($c, ($k << 1) + 1, 1) || push(@primes, ($k << 1) + 1);
    }
    return @primes;
}

my $n      = shift(@ARGV) // 100;
my @primes = bitstring_prime_sieve($n);
say join(' ', @primes);
say "PI($n) = ", scalar(@primes);
