#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13 May 2017
# Edit: 05 June 2026 (precision optimization)
# https://github.com/trizen

# Computation of the n-th Bernoulli number using prime numbers.
# Algorithm: Kevin J. McGown, "Computing Bernoulli Numbers Quickly" (2005)

use 5.010;
use strict;
use warnings;

use Math::GMPz;
use Math::GMPq;
use Math::MPFR;

use ntheory qw(is_prob_prime forprimes fordivisors);

sub bern_from_primes {
    my ($n) = @_;

    return Math::GMPq->new('1')   if $n == 0;
    return Math::GMPq->new('1/2') if $n == 1;
    return undef                  if $n < 0;
    return Math::GMPq->new('0')   if $n % 2;

    my $TAU = 6.28318530717958647692528676655900576839433879875021;

    # von Staudt-Clausen denominator
    # d = ∏ { p prime : (p−1) | n }
    # Computing d first lets us measure its exact bit-length for the precision.
    my $d = Math::GMPz::Rmpz_init_set_ui(1);
    fordivisors {
        Math::GMPz::Rmpz_mul_ui($d, $d, $_ + 1) if is_prob_prime($_ + 1);
    } $n;

    # We need enough bits to represent |numerator of B_n| = |B_n| · d exactly,
    # then round correctly. Use Stirling to bound log₂|B_n|, and the exact
    # bit-length of d (always ≤ n, but usually far smaller in practice).
    my $log2B = (log(4 * $TAU * $n) / 2 + $n * (log($n) - log($TAU) - 1)) / log(2);
    my $prec  = int($log2B) + Math::GMPz::Rmpz_sizeinbase($d, 2) + 64;

    # K = 2·n! / (2π)^n ---
    # This is the conversion factor B_n = K · ζ(n).
    my $fac = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_fac_ui($fac, $n);

    my $K = Math::MPFR::Rmpfr_init2($prec);
    Math::MPFR::Rmpfr_const_pi($K, 2);
    Math::MPFR::Rmpfr_pow_ui($K, $K, $n, 0);         # π^n
    Math::MPFR::Rmpfr_mul_2ui($K, $K, $n - 1, 0);    # 2^(n−1) · π^n
    Math::MPFR::Rmpfr_div_z($K, $K, $fac, 0);        # ÷ n!
    Math::MPFR::Rmpfr_ui_div($K, 1, $K, 0);          # K = n! / (2^(n−1)·π^n)

    # Upper bound N for the truncated Euler product
    my $Nf = Math::MPFR::Rmpfr_init2(64);
    Math::MPFR::Rmpfr_mul_z($Nf, $K, $d, 0);            # Nf = K·d
    Math::MPFR::Rmpfr_rootn_ui($Nf, $Nf, $n - 1, 0);    # Nf = (K·d)^(1/(n−1))
    Math::MPFR::Rmpfr_ceil($Nf, $Nf);
    my $N = Math::MPFR::Rmpfr_get_ui($Nf, 0);

    # Truncated Euler product ≈ ζ(n)
    # z = ∏_{p ≤ N} p^n / (p^n − 1)
    my $z   = Math::MPFR::Rmpfr_init2($prec);
    my $tmp = Math::GMPz::Rmpz_init();
    Math::MPFR::Rmpfr_set_ui($z, 1, 0);

    forprimes {
        Math::GMPz::Rmpz_ui_pow_ui($tmp, $_, $n);    # tmp = p^n
        Math::MPFR::Rmpfr_mul_z($z, $z, $tmp, 0);    # z  *= p^n
        Math::GMPz::Rmpz_sub_ui($tmp, $tmp, 1);      # tmp = p^n − 1
        Math::MPFR::Rmpfr_div_z($z, $z, $tmp, 0);    # z  /= (p^n − 1)
    } $N;

    # z · K · d  →  |B_n · d|  =  |numerator of B_n|
    Math::MPFR::Rmpfr_mul($z, $z, $K, 0);
    Math::MPFR::Rmpfr_mul_z($z, $z, $d, 0);
    Math::MPFR::Rmpfr_ceil($z, $z);

    # Sign: B_n < 0 iff n ≡ 0 (mod 4).
    Math::MPFR::Rmpfr_get_z($fac, $z, 0);
    Math::GMPz::Rmpz_neg($fac, $fac) if $n % 4 == 0;

    my $q = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set_num($q, $fac);
    Math::GMPq::Rmpq_set_den($q, $d);

    return $q;
}

for my $i (0 .. 50) {
    printf "B%-3d = %s\n", 2 * $i, bern_from_primes(2 * $i);
}
