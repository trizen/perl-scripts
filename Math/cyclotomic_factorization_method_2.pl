#!/usr/bin/perl

# Author: Trizen
# Date: 23 May 2022
# https://github.com/trizen

# A variant of the Cyclotomic factorization method.

# See also:
#   https://www.ams.org/journals/mcom/1989-52-185/S0025-5718-1989-0947467-1/S0025-5718-1989-0947467-1.pdf

use 5.020;
use strict;
use warnings;

use Math::GMPz;
use ntheory qw(:all);
use POSIX qw(ULONG_MAX);

use experimental qw(signatures);

sub cyclotomic_factor ($n, @bases) {

    $n = Math::GMPz->new("$n");

    Math::GMPz::Rmpz_cmp_ui($n, 1) > 0 or return;

    if (@bases) {
        @bases = map { Math::GMPz->new("$_") } @bases;
    }
    else {
        @bases = map { Math::GMPz->new($_) } (2 .. logint($n, 2));
    }

    my $cyclotomicmod = sub ($n, $x, $m) {

        my @factor_exp = factor_exp($n);

        # Generate the squarefree divisors of n, along
        # with the number of prime factors of each divisor
        my @sd;
        foreach my $pe (@factor_exp) {
            my ($p) = @$pe;
            push @sd, map { [$_->[0] * $p, $_->[1] + 1] } @sd;
            push @sd, [$p, 1];
        }

        push @sd, [Math::GMPz::Rmpz_init_set_ui(1), 0];

        my $prod = Math::GMPz::Rmpz_init_set_ui(1);

        foreach my $pair (@sd) {
            my ($d, $c) = @$pair;

            my $base = Math::GMPz::Rmpz_init();
            my $exp  = CORE::int($n / $d);

            Math::GMPz::Rmpz_powm_ui($base, $x, $exp, $m);    # x^(n/d) mod m
            Math::GMPz::Rmpz_sub_ui($base, $base, 1);

            if ($c % 2 == 1) {
                Math::GMPz::Rmpz_invert($base, $base, $m) || return $base;
            }

            Math::GMPz::Rmpz_mul($prod, $prod, $base);
            Math::GMPz::Rmpz_mod($prod, $prod, $m);
        }

        $prod;
    };

    my @factors;
    state $g = Math::GMPz::Rmpz_init_nobless();

  OUTER: foreach my $x (@bases) {
        my $limit = 1 + logint($n, $x);

        foreach my $k (3 .. $limit) {
            my $c = $cyclotomicmod->($k, $x, $n);

            Math::GMPz::Rmpz_gcd($g, $n, $c);
            if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0 and Math::GMPz::Rmpz_cmp($g, $n) < 0) {

                my $valuation = Math::GMPz::Rmpz_remove($n, $n, $g);
                push(@factors, (Math::GMPz::Rmpz_init_set($g)) x $valuation);

                if (Math::GMPz::Rmpz_cmp_ui($n, 1) == 0 or is_prob_prime($n)) {
                    last OUTER;
                }
            }
        }
    }

    if (Math::GMPz::Rmpz_cmp_ui($n, 1) > 0) {
        push @factors, $n;
    }

    @factors = sort { Math::GMPz::Rmpz_cmp($a, $b) } @factors;
    return @factors;
}

say join ' * ', cyclotomic_factor(Math::GMPz->new(2)**120 + 1);
say join ' * ', cyclotomic_factor(Math::GMPz->new(2)**128 - 1);
say join ' * ', cyclotomic_factor(((Math::GMPz->new(10)**258 - 1) / 9 - Math::GMPz->new(10)**(258 >> 1) - 1), 10);

__END__
257 * 65281 * 4278255361 * 18518800563924107521
3 * 5 * 17 * 257 * 65537 * 4294967297 * 18446744073709551617
10 * 11 * 11 * 91 * 101 * 10001 * 100000001 * 10000000000000001 * 100000000000000000000000000000001 * 909090909090909090909090909090909090909091 * 10000000000000000000000000000000000000000000000000000000000000001 * 1098901098901098901098901098901098901098900989010989010989010989010989010989010989011
