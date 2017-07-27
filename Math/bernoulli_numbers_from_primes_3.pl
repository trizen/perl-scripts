#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13 May 2017
# https://github.com/trizen

# Computation of the nth-Bernoulli number, using prime numbers.

# Algorithm due to Kevin J. McGown (December 8, 2005)
# See his paper: "Computing Bernoulli Numbers Quickly"

use 5.010;
use strict;
use warnings;

use Math::GMPz;
use Math::GMPq;
use Math::MPFR;

use ntheory qw(is_prob_prime forprimes fordivisors);

sub bern_from_primes {
    my ($n) = @_;

    $n == 0 and return Math::GMPq->new('1');
    $n == 1 and return Math::GMPq->new('1/2');
    $n <  0 and return undef;
    $n %  2 and return Math::GMPq->new('0');

    my $round = Math::MPFR::MPFR_RNDN();

    my $tau   = 6.28318530717958647692528676655900576839433879875;
    my $log2B = (log(4 * $tau * $n) / 2 + $n * log($n) - $n * log($tau) - $n) / log(2);

    my $prec = int($n + $log2B) + ($n <= 90 ? 18 : 0);

    my $d = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_fac_ui($d, $n);                      # d = n!

    my $K = Math::MPFR::Rmpfr_init2($prec);
    Math::MPFR::Rmpfr_const_pi($K, $round);               # K = pi
    Math::MPFR::Rmpfr_pow_ui($K, $K, $n, $round);         # K = K^n
    Math::MPFR::Rmpfr_mul_2ui($K, $K, $n - 1, $round);    # K = K * 2^(n-1)
    Math::MPFR::Rmpfr_div_z($K, $K, $d, $round);          # K = K / d
    Math::MPFR::Rmpfr_ui_div($K, 1, $K, $round);          # K = 1 / K

    Math::GMPz::Rmpz_set_ui($d, 1);                       # d = 1

    fordivisors {                                         # divisors of n
        if (is_prob_prime($_ + 1)) {
            Math::GMPz::Rmpz_mul_ui($d, $d, $_ + 1);      # d = d * p, where (p-1)|n
        }
    } $n;

    my $N = Math::MPFR::Rmpfr_init2(64);
    Math::MPFR::Rmpfr_mul_z($N, $K, $d, $round);          # N = K * d
    Math::MPFR::Rmpfr_root($N, $N, $n - 1, $round);       # N = K^(1/(n-1))
    Math::MPFR::Rmpfr_ceil($N, $N);                       # N = ceil(N)

    $N = Math::MPFR::Rmpfr_get_ui($N, $round);

    my $z = Math::MPFR::Rmpfr_init2($prec);               # zeta(n)
    my $u = Math::GMPz::Rmpz_init();                      # p^n

    Math::MPFR::Rmpfr_set_ui($z, 1, $round);              # z = 1

    forprimes {                                           # primes <= N
        Math::GMPz::Rmpz_ui_pow_ui($u, $_, $n);           # u = p^n
        Math::MPFR::Rmpfr_mul_z($z, $z, $u, $round);      # z = z*u
        Math::GMPz::Rmpz_sub_ui($u, $u, 1);               # u = u-1
        Math::MPFR::Rmpfr_div_z($z, $z, $u, $round);      # z = z/u
    } $N;

    Math::MPFR::Rmpfr_mul($z, $z, $K, $round);            # z = z * K
    Math::MPFR::Rmpfr_mul_z($z, $z, $d, $round);          # z = z * d
    Math::MPFR::Rmpfr_ceil($z, $z);                       # z = ceil(z)

    my $q = Math::GMPq::Rmpq_init();

    Math::GMPq::Rmpq_set_den($q, $d);                     # denominator
    Math::MPFR::Rmpfr_get_z($d, $z, $round);
    Math::GMPz::Rmpz_neg($d, $d) if $n % 4 == 0;          # d = -d, iff 4|n
    Math::GMPq::Rmpq_set_num($q, $d);                     # numerator

    return $q;                                            # Bn
}

foreach my $i (0 .. 50) {
    printf "B%-3d = %s\n", 2 * $i, bern_from_primes(2 * $i);
}
