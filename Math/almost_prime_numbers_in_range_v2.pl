#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 15 February 2021
# Edit: 06 August 2024
# https://github.com/trizen

# Generate k-almost prime numbers in range [a,b]. (not in sorted order)

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime

use 5.036;
use ntheory qw(:all);

sub almost_prime_numbers ($A, $B, $k, $callback) {

    $A = vecmax($A, powint(2, $k));

    sub ($m, $lo, $k) {

        if ($k == 1) {

            forprimes {
                $callback->($m * $_);
            } vecmax($lo, cdivint($A, $m)), divint($B, $m);

            return;
        }

        my $hi = rootint(divint($B, $m), $k);

        foreach my $p (@{primes($lo, $hi)}) {
            __SUB__->($m * $p, $p, $k - 1);
        }
      }
      ->(1, 2, $k);
}

# Generate 5-almost primes in the range [50, 1000]

my $k    = 5;
my $from = 50;
my $upto = 1000;

my @arr;
almost_prime_numbers($from, $upto, $k, sub ($n) { push @arr, $n });

my @test = grep { is_almost_prime($k, $_) } $from .. $upto;    # just for testing
join(' ', sort { $a <=> $b } @arr) eq join(' ', @test) or die "Error: not equal!";

say join(', ', @arr);
