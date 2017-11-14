#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 14 November 2017
# https://github.com/trizen

# Efficient algorithm for computing the nth-Bernoulli number, using prime numbers.

# Algorithm due to Kevin J. McGown (December 8, 2005)
# See his paper: "Computing Bernoulli Numbers Quickly"

# Run times:
#   bern( 40_000) - 2.763s
#   bern(100_000) - 19.591s
#   bern(200_000) - 1 min, 27.21s

use 5.010;
use strict;
use warnings;

use Math::GMPz;
use Math::GMPq;
use Math::GMPf;
use Math::MPFR;

sub bern_from_primes {
    my ($n) = @_;

    $n == 0 and return Math::GMPq->new('1');
    $n == 1 and return Math::GMPq->new('1/2');
    $n <  0 and return undef;
    $n %  2 and return Math::GMPq->new('0');

    state $round = Math::MPFR::MPFR_RNDN();
    state $tau   = 6.28318530717958647692528676655900576839433879875;

    my $log2B = (CORE::log(4 * $tau * $n) / 2 + $n * (CORE::log($n / $tau) - 1)) / CORE::log(2);

    my $prec = CORE::int($n + $log2B) +
          ($n <= 90 ? (3, 3, 4, 4, 7, 6, 6, 6, 7, 7, 7, 8, 8, 9, 10, 12, 9, 7, 6, 0, 0, 0,
                       0, 0, 0, 0, 0, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4)[($n>>1)-1] : 0);

    state $d = Math::GMPz::Rmpz_init_nobless();
    Math::GMPz::Rmpz_fac_ui($d, $n);                      # d = n!

    my $K = Math::MPFR::Rmpfr_init2($prec);
    Math::MPFR::Rmpfr_const_pi($K, $round);               # K = pi
    Math::MPFR::Rmpfr_pow_si($K, $K, -$n, $round);        # K = K^(-n)
    Math::MPFR::Rmpfr_mul_z($K, $K, $d, $round);          # K = K*d
    Math::MPFR::Rmpfr_div_2ui($K, $K, $n - 1, $round);    # K = K / 2^(n-1)

    # `d` is the denominator of bernoulli(n)
    Math::GMPz::Rmpz_set_ui($d, 2);                       # d = 2

    my @primes = (2);

    {
        # Sieve the primes <= n+1
        # Sieve of Eratosthenes + Dana Jacobsen's optimizations

        my $N = $n + 1;

        my @composite;
        my $bound = CORE::int(CORE::sqrt($N));

        for (my $i = 3 ; $i <= $bound ; $i += 2) {
            if (!exists($composite[$i])) {
                for (my $j = $i * $i ; $j <= $N ; $j += 2 * $i) {
                    undef $composite[$j];
                }
            }
        }

        foreach my $k (1 .. ($N - 1) >> 1) {
            if (!exists($composite[2 * $k + 1])) {

                push(@primes, 2 * $k + 1);

                if ($n % (2 * $k) == 0) {    # d = d*p   iff (p-1)|n
                    Math::GMPz::Rmpz_mul_ui($d, $d, 2 * $k + 1);
                }
            }
        }
    }

    state $N = Math::MPFR::Rmpfr_init2_nobless(64);
    Math::MPFR::Rmpfr_mul_z($K, $K, $d, $round);         # K = K*d
    Math::MPFR::Rmpfr_root($N, $K, $n - 1, $round);      # N = N^(1/(n-1))
    Math::MPFR::Rmpfr_ceil($N, $N);                      # N = ceil(N)

    my $bound = Math::MPFR::Rmpfr_get_ui($N, $round);    # bound = int(N)

    my $t = Math::GMPf::Rmpf_init2($prec);               # temporary variable
    my $f = Math::GMPf::Rmpf_init2($prec);               # approximation to zeta(n)

    Math::MPFR::Rmpfr_get_f($f, $K, $round);

    for (my $i = 0 ; $primes[$i] <= $bound ; ++$i) {  # primes <= N
        Math::GMPf::Rmpf_set_ui($t, $primes[$i]);        # t = p
        Math::GMPf::Rmpf_pow_ui($t, $t, $n);             # t = t^n
        Math::GMPf::Rmpf_mul($f, $f, $t);                # f = f*t
        Math::GMPf::Rmpf_sub_ui($t, $t, 1);              # t = t-1
        Math::GMPf::Rmpf_div($f, $f, $t);                # f = f/t
    }

    my $q = Math::GMPq::Rmpq_init();

    Math::GMPf::Rmpf_ceil($f, $f);                       # f = ceil(f)
    Math::GMPq::Rmpq_set_f($q, $f);                      # q = f

    Math::GMPq::Rmpq_set_den($q, $d);                    # denominator
    Math::GMPq::Rmpq_neg($q, $q) if $n % 4 == 0;         # q = -q, iff 4|n

    return $q;                                           # Bn
}

foreach my $i (0 .. 50) {
    printf "B%-3d = %s\n", 2 * $i, bern_from_primes(2 * $i);
}
