#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 18 May 2017
# https://github.com/trizen

# A binary sieve for prime numbers.

# Useful only when memory is very restricted.

use 5.010;
use strict;
use warnings;

use Math::GMPz;

sub binary_prime_sieve {
    my ($n) = @_;

    my $t = Math::GMPz::Rmpz_init_set_ui(1);
    my $c = Math::GMPz::Rmpz_init_set_ui(1);

    Math::GMPz::Rmpz_mul_2exp($c, $c, $n);

    foreach my $i (2 .. sqrt($n)) {
        Math::GMPz::Rmpz_mul_2exp($t, $t, $n - $i**2);

        for (my $j = $i**2 ; $j <= $n ; $j += $i) {
            Math::GMPz::Rmpz_ior($c, $c, $t);
            Math::GMPz::Rmpz_div_2exp($t, $t, $i);
        }

        Math::GMPz::Rmpz_set_ui($t, 1);
    }

    my $bin = Math::GMPz::Rmpz_get_str($c, 2);

    my @primes;
    foreach my $p (2 .. $n) {
        substr($bin, $p, 1) || push(@primes, $p);
    }
    return @primes;
}

my $n = shift(@ARGV) // 100;
my @primes = binary_prime_sieve($n);
say join(' ', @primes);
say "PI($n) = ", scalar(@primes);
