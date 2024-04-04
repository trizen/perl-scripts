#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 15 February 2021
# Edit: 04 April 2024
# https://github.com/trizen

# Generate all the k-almost prime numbers in range [A,B].

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime

use 5.036;
use ntheory qw(:all);
use Math::GMPz;

sub almost_prime_numbers ($A, $B, $k) {

    my $u = Math::GMPz::Rmpz_init();
    my $v = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_setbit($u, $k);

    $A = vecmax($A, $u);
    $A = Math::GMPz->new("$A");
    $B = Math::GMPz->new("$B");

    my @values = sub ($m, $lo, $k) {

        Math::GMPz::Rmpz_tdiv_q($u, $B, $m);
        Math::GMPz::Rmpz_root($u, $u, $k);

        my $hi = Math::GMPz::Rmpz_get_ui($u);

        if ($lo > $hi) {
            return;
        }

        my @lst;

        if ($k == 1) {

            Math::GMPz::Rmpz_cdiv_q($u, $A, $m);

            if (Math::GMPz::Rmpz_fits_ulong_p($u)) {
                $lo = vecmax($lo, Math::GMPz::Rmpz_get_ui($u));
            }
            elsif (Math::GMPz::Rmpz_cmp_ui($u, $lo) > 0) {
                if (Math::GMPz::Rmpz_cmp_ui($u, $hi) > 0) {
                    return;
                }
                $lo = Math::GMPz::Rmpz_get_ui($u);
            }

            if ($lo > $hi) {
                return;
            }

            foreach my $p (@{primes($lo, $hi)}) {
                my $v = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_mul_ui($v, $m, $p);
                push @lst, $v;
            }

            return @lst;
        }

        my $z = Math::GMPz::Rmpz_init();

        foreach my $p (@{primes($lo, $hi)}) {
            Math::GMPz::Rmpz_mul_ui($z, $m, $p);

            Math::GMPz::Rmpz_cdiv_q($u, $A, $z);
            Math::GMPz::Rmpz_tdiv_q($v, $B, $z);

            if (Math::GMPz::Rmpz_cmp($u, $v) <= 0) {
                push @lst, __SUB__->($z, $p, $k - 1);
            }
        }

        return @lst;
      }
      ->(Math::GMPz->new(1), 2, $k);

    sort { Math::GMPz::Rmpz_cmp($a, $b) } @values;
}

# Generate 5-almost primes in the range [50, 1000]

my $k    = 5;
my $from = 50;
my $upto = 1000;

my @arr  = almost_prime_numbers($from, $upto, $k);
my @test = grep { is_almost_prime($k, $_) } $from .. $upto;    # just for testing

join(' ', @arr) eq join(' ', @test) or die "Error: not equal!";

say join(', ', @arr);
