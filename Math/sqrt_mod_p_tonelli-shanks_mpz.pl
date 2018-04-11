#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 11 April 2018
# https://github.com/trizen

# An efficient implementation of the Tonelli-Shanks algorithm, using Math::GMPz.

use 5.020;
use strict;
use warnings;

use Math::GMPz;
use experimental qw(signatures);

sub sqrt_mod ($n, $p) {

    if (ref($n) ne 'Math::GMPz') {
        $n = Math::GMPz::Rmpz_init_set_str("$n", 10);
    }

    if (ref($p) ne 'Math::GMPz') {
        $p = Math::GMPz::Rmpz_init_set_str("$p", 10);
    }

    my $q = Math::GMPz::Rmpz_init_set($p);

    if (Math::GMPz::Rmpz_divisible_p($n, $p)) {
        Math::GMPz::Rmpz_mod($q, $q, $p);
        return $q;
    }

    if (Math::GMPz::Rmpz_legendre($n, $p) != 1) {
        die "Not a quadratic residue!";
    }

    if (Math::GMPz::Rmpz_tstbit($p, 1) == 1) {    # p = 3 (mod 4)

        # q = n ^ ((p+1) / 4) (mod p)
        Math::GMPz::Rmpz_add_ui($q, $q, 1);       # q = p+1
        Math::GMPz::Rmpz_fdiv_q_2exp($q, $q, 2);  # q = (p+1)/4
        Math::GMPz::Rmpz_powm($q, $n, $q, $p);    # q = n^q (mod p)
        return $q;
    }

    Math::GMPz::Rmpz_sub_ui($q, $q, 1);           # q = p-1

    # Factor out 2^s from q
    my $s = Math::GMPz::Rmpz_remove($q, $q, Math::GMPz::Rmpz_init_set_ui(2));

    # Search for a non-residue mod p by picking the first w such that (w|p) is -1
    my $w = 2;
    while (Math::GMPz::Rmpz_ui_kronecker($w, $p) != -1) { ++$w }
    $w = Math::GMPz::Rmpz_init_set_ui($w);

    Math::GMPz::Rmpz_powm($w, $w, $q, $p);    # w = w^q (mod p)
    Math::GMPz::Rmpz_add_ui($q, $q, 1);       # q = q+1
    Math::GMPz::Rmpz_fdiv_q_2exp($q, $q, 1);  # q = (q+1) / 2

    my $n_inv = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_powm($q, $n, $q, $p);    # q = n^q (mod p)
    Math::GMPz::Rmpz_invert($n_inv, $n, $p);

    my $y = Math::GMPz::Rmpz_init();

    for (; ;) {
        Math::GMPz::Rmpz_powm_ui($y, $q, 2, $p);    # y = q^2 (mod p)
        Math::GMPz::Rmpz_mul($y, $y, $n_inv);
        Math::GMPz::Rmpz_mod($y, $y, $p);           # y = y * n^-1 (mod p)

        my $i = 0;

        for (; Math::GMPz::Rmpz_cmp_ui($y, 1) ; ++$i) {
            Math::GMPz::Rmpz_powm_ui($y, $y, 2, $p);    #  y = y ^ 2 (mod p)
        }

        if ($i == 0) {                                # q^2 * n^-1 = 1 (mod p)
            return $q;
        }

        if ($s - $i == 1) {
            Math::GMPz::Rmpz_mul($q, $q, $w);
        }
        else {
            Math::GMPz::Rmpz_powm_ui($y, $w, 1 << ($s - $i - 1), $p);
            Math::GMPz::Rmpz_mul($q, $q, $y);
        }

        Math::GMPz::Rmpz_mod($q, $q, $p);
    }

    return $q;
}

say sqrt_mod('1030',                                               '10009');
say sqrt_mod('44402',                                              '100049');
say sqrt_mod('665820697',                                          '1000000009');
say sqrt_mod('881398088036',                                       '1000000000039');
say sqrt_mod('41660815127637347468140745042827704103445750172002', '100000000000000000000000000000000000000000000000577');
