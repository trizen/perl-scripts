#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 09 July 2017
# https://github.com/trizen

# A decently fast bit-string sieve for prime numbers.
# It's asymptotically faster than using Perl's arrays.

# Also useful when memory is very restricted.

use 5.010;
use strict;
use warnings;

use Math::GMPz;

sub bitstring_prime_sieve {
    my ($n) = @_;

    my $c = Math::GMPz::Rmpz_init_set_ui(1);

    Math::GMPz::Rmpz_mul_2exp($c, $c, $n);

    foreach my $i (2 .. sqrt($n)) {
        if (!Math::GMPz::Rmpz_tstbit($c, $i)) {
            for (my $j = $i**2 ; $j <= $n ; $j += $i) {
                Math::GMPz::Rmpz_setbit($c, $j);
            }
        }
    }

    my @primes;
    foreach my $p (2 .. $n) {
        Math::GMPz::Rmpz_tstbit($c, $p) || push(@primes, $p);
    }
    return @primes;
}

my $n = shift(@ARGV) // 100;
my @primes = bitstring_prime_sieve($n);
say join(' ', @primes);
say "PI($n) = ", scalar(@primes);
