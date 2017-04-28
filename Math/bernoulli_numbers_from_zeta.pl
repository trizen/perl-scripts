#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13 October 2016
# Website: https://github.com/trizen

# Computation of the nth-Bernoulli number, using the Zeta function.

use 5.010;
use strict;
use warnings;

use Math::AnyNum;

sub bern_zeta {
    my ($n) = @_;

    # B(n) = (-1)^(n/2 + 1) * zeta(n)*2*n! / (2*pi)^n

    $n == 0 and return Math::AnyNum->one;
    $n == 1 and return Math::AnyNum->new('1/2');
    $n < 0  and return Math::AnyNum->nan;
    $n % 2  and return Math::AnyNum->zero;

    my $ROUND = Math::MPFR::MPFR_RNDN();

    # The required precision is: O(n*log(n))
    my $prec = (
        $n <= 156
        ? CORE::int($n * CORE::log($n) + 1)
        : CORE::int($n * CORE::log($n) / CORE::log(2) - 3 * $n)
    );

    my $f = Math::MPFR::Rmpfr_init2($prec);
    Math::MPFR::Rmpfr_zeta_ui($f, $n, $ROUND);                     # f = zeta(n)

    my $z = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_fac_ui($z, $n);                               # z = n!
    Math::GMPz::Rmpz_div_2exp($z, $z, $n - 1);                     # z = z / 2^(n-1)
    Math::MPFR::Rmpfr_mul_z($f, $f, $z, $ROUND);                   # f = f*z

    my $p = Math::MPFR::Rmpfr_init2($prec);
    Math::MPFR::Rmpfr_const_pi($p, $ROUND);                        # p = PI
    Math::MPFR::Rmpfr_pow_ui($p, $p, $n, $ROUND);                  # p = p^n
    Math::MPFR::Rmpfr_div($f, $f, $p, $ROUND);                     # f = f/p

    Math::GMPz::Rmpz_set_ui($z, 1);                                # z = 1
    Math::GMPz::Rmpz_mul_2exp($z, $z, $n + 1);                     # z = 2^(n+1)
    Math::GMPz::Rmpz_sub_ui($z, $z, 2);                            # z = z-2

    Math::MPFR::Rmpfr_mul_z($f, $f, $z, $ROUND);                   # f = f*z
    Math::MPFR::Rmpfr_round($f, $f);                               # f = [f]

    my $q = Math::GMPq::Rmpq_init();
    Math::MPFR::Rmpfr_get_q($q, $f);                               # q = f
    Math::GMPq::Rmpq_set_den($q, $z);                              # q = q/z
    Math::GMPq::Rmpq_canonicalize($q);                             # remove common factors

    Math::GMPq::Rmpq_neg($q, $q) if $n % 4 == 0;                   # q = -q    (iff 4|n)
    Math::AnyNum->new($q);
}

foreach my $i (0 .. 50) {
    printf "B%-3d = %s\n", 2 * $i, bern_zeta(2 * $i);
}
