#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 14 March 2021
# Edit: 04 April 2024
# https://github.com/trizen

# Generate all the k-omega primes in range [A,B].

# Definition:
#   k-omega primes are numbers n such that omega(n) = k.

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://en.wikipedia.org/wiki/Prime_omega_function

use 5.036;
use Math::GMPz;
use ntheory qw(:all);

sub omega_prime_numbers ($A, $B, $k) {

    $A = vecmax($A, pn_primorial($k));
    $A = Math::GMPz->new("$A");
    $B = Math::GMPz->new("$B");

    my $u = Math::GMPz::Rmpz_init();

    my @values = sub ($m, $lo, $j) {

        Math::GMPz::Rmpz_tdiv_q($u, $B, $m);
        Math::GMPz::Rmpz_root($u, $u, $j);

        my $hi = Math::GMPz::Rmpz_get_ui($u);

        if ($lo > $hi) {
            return;
        }

        my @lst;
        my $v = Math::GMPz::Rmpz_init();

        foreach my $q (@{primes($lo, $hi)}) {

            Math::GMPz::Rmpz_mul_ui($v, $m, $q);

            while (Math::GMPz::Rmpz_cmp($v, $B) <= 0) {
                if ($j == 1) {
                    if (Math::GMPz::Rmpz_cmp($v, $A) >= 0) {
                        push @lst, Math::GMPz::Rmpz_init_set($v);
                    }
                }
                else {
                    push @lst, __SUB__->($v, $q + 1, $j - 1);
                }
                Math::GMPz::Rmpz_mul_ui($v, $v, $q);
            }
        }

        return @lst;
      }
      ->(Math::GMPz->new(1), 2, $k);

    sort { Math::GMPz::Rmpz_cmp($a, $b) } @values;
}

# Generate 5-omega primes in the range [3000, 10000]

my $k    = 5;
my $from = 3000;
my $upto = 10000;

my @arr  = omega_prime_numbers($from, $upto, $k);
my @test = grep { prime_omega($_) == $k } $from .. $upto;    # just for testing

join(' ', @arr) eq join(' ', @test) or die "Error: not equal!";

say join(', ', @arr);

# Run some tests

foreach my $k (1 .. 6) {

    my $from = pn_primorial($k) + int(rand(1e4));
    my $upto = $from + int(rand(1e5));

    say "Testing: $k with $from .. $upto";

    my @arr  = omega_prime_numbers($from, $upto, $k);
    my @test = grep { prime_omega($_) == $k } $from .. $upto;
    join(' ', @arr) eq join(' ', @test) or die "Error: not equal!";
}
