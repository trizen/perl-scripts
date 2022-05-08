#!/usr/bin/perl

# Author: Trizen
# Date: 08 May 2022
# https://github.com/trizen

# Efficiently compute the n-th Cyclotomic polynomial modulo m, evaluated at x.

use 5.020;
use strict;
use warnings;

use Math::GMPz;
use ntheory qw(:all);
use experimental qw(signatures);

sub cyclotomicmod ($n, $x, $m) {

    $n = Math::GMPz->new("$n");
    $x = Math::GMPz->new("$x");
    $m = Math::GMPz->new("$m");

    Math::GMPz::Rmpz_sgn($m) || return;

    # n must be >= 0
    (Math::GMPz::Rmpz_sgn($n) || return 0) > 0
      or return;

    return 0 if (Math::GMPz::Rmpz_cmp_ui($m, 1) == 0);

    return (($x - 1) % $m) if (Math::GMPz::Rmpz_cmp_ui($n, 1) == 0);
    return (($x + 1) % $m) if (Math::GMPz::Rmpz_cmp_ui($n, 2) == 0);

    my @factor_exp = factor_exp($n);

    # Special case for x = 1: cyclotomic(n, 1) is the greatest common divisor of the prime factors of n.
    if (Math::GMPz::Rmpz_cmp_ui($x, 1) == 0) {
        return modint(gcd(map { $_->[0] } @factor_exp), $m);
    }

    # Generate the squarefree divisors of n, along
    # with the number of prime factors of each divisor
    my @sd;
    foreach my $pe (@factor_exp) {
        my ($p) = @$pe;

        $p =
          ($p < ~0)
          ? Math::GMPz::Rmpz_init_set_ui($p)
          : Math::GMPz::Rmpz_init_set_str("$p", 10);

        push @sd, map { [$_->[0] * $p, $_->[1] + 1] } @sd;
        push @sd, [$p, 1];
    }

    push @sd, [Math::GMPz::Rmpz_init_set_ui(1), 0];

    my $prod = Math::GMPz::Rmpz_init_set_ui(1);

    foreach my $pair (@sd) {
        my ($d, $c) = @$pair;

        my $base = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_divexact($base, $n, $d);
        Math::GMPz::Rmpz_powm($base, $x, $base, $m);    # x^(n/d) mod m
        Math::GMPz::Rmpz_sub_ui($base, $base, 1);

        if ($c % 2 == 1) {
            Math::GMPz::Rmpz_invert($base, $base, $m) || return;
        }

        Math::GMPz::Rmpz_mul($prod, $prod, $base);
        Math::GMPz::Rmpz_mod($prod, $prod, $m);
    }

    return $prod;
}

say cyclotomicmod(factorial(30), 5040,                        Math::GMPz->new(2)**128 + 1);
say cyclotomicmod(factorial(20), Math::GMPz->new(2)**127 - 1, Math::GMPz->new(2)**128 + 1);

__END__
40675970320518606495224484019728682382
194349103384996189019641296094415725728
