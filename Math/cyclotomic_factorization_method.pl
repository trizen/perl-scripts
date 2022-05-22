#!/usr/bin/perl

# Author: Trizen
# Date: 22 May 2022
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

sub cyclotomic_factor ($m, $n = 3628800, $upto = 100) {

    $n = Math::GMPz->new("$n");
    $m = Math::GMPz->new("$m");

    Math::GMPz::Rmpz_sgn($m) || return 1;

    # n must be >= 0
    (Math::GMPz::Rmpz_sgn($n) || return 1) > 0
      or return 1;

    return 1 if (Math::GMPz::Rmpz_cmp_ui($m, 1) == 0);

    my @factor_exp = factor_exp($n);

    # Generate the squarefree divisors of n, along
    # with the number of prime factors of each divisor
    my @sd;
    foreach my $pe (@factor_exp) {
        my ($p) = @$pe;

        $p =
          ($p < ULONG_MAX)
          ? Math::GMPz::Rmpz_init_set_ui($p)
          : Math::GMPz::Rmpz_init_set_str("$p", 10);

        push @sd, map { [$_->[0] * $p, $_->[1] + 1] } @sd;
        push @sd, [$p, 1];
    }

    push @sd, [Math::GMPz->new(1), 0];

    my $prod = Math::GMPz::Rmpz_init_set_ui(1);
    my $g    = Math::GMPz::Rmpz_init();
    my $x    = Math::GMPz::Rmpz_init_set_ui(2);

    foreach my $k (2 .. $upto) {
        my $x = Math::GMPz::Rmpz_init_set_ui($k);

        foreach my $pair (@sd) {
            my ($d, $c) = @$pair;

            my $base = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_divexact($base, $n, $d);
            Math::GMPz::Rmpz_powm($base, $x, $base, $m);    # x^(n/d) mod m
            Math::GMPz::Rmpz_sub_ui($base, $base, 1);

            Math::GMPz::Rmpz_gcd($g, $base, $m);

            if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
                last if (Math::GMPz::Rmpz_cmp($g, $m) == 0);
                return $g;
            }

            if ($c % 2 == 1) {
                Math::GMPz::Rmpz_invert($base, $base, $m);
            }

            Math::GMPz::Rmpz_mul($prod, $prod, $base);
            Math::GMPz::Rmpz_mod($prod, $prod, $m);
        }
    }

    return 1;
}

say cyclotomic_factor(Math::GMPz->new(2)**64 + 1,  40320, 100);     #=> 274177
say cyclotomic_factor(Math::GMPz->new(2)**128 - 1, 40320, 100);     #=> 18446744073709551615
