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

sub bern_from_primes {
    my ($n) = @_;

    $n == 0 and return Math::GMPq->new('1');
    $n == 1 and return Math::GMPq->new('1/2');
    $n < 0  and return undef;
    $n % 2  and return Math::GMPq->new('0');

    my $round = Math::MPFR::MPFR_RNDN();

    # The required precision is: O(n*log(n))
    my $prec = (
                $n <= 156
                ? CORE::int($n * CORE::log($n) + 1)
                : CORE::int($n * CORE::log($n) / CORE::log(2) - 3 * $n)
               );

    my $d = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_fac_ui($d, $n);
    Math::GMPz::Rmpz_mul_2exp($d, $d, 1);

    my $K = Math::MPFR::Rmpfr_init2($prec);
    Math::MPFR::Rmpfr_const_pi($K, $round);
    Math::MPFR::Rmpfr_pow_ui($K, $K, $n, $round);
    Math::MPFR::Rmpfr_mul_2ui($K, $K, $n, $round);

    Math::MPFR::Rmpfr_div_z($K, $K, $d, $round);
    Math::MPFR::Rmpfr_ui_div($K, 1, $K, $round);

    Math::GMPz::Rmpz_set_ui($d, 1);

#<<<
    for (my $p = Math::GMPz::Rmpz_init_set_ui(2) ;
         Math::GMPz::Rmpz_cmp_ui($p, $n + 1) <= 0 ;
         Math::GMPz::Rmpz_nextprime($p, $p)
    ) {
        if ($n % (Math::GMPz::Rmpz_get_ui($p) - 1) == 0) {
            Math::GMPz::Rmpz_mul($d, $d, $p);
        }
    }
#>>>

    my $N = Math::MPFR::Rmpfr_init2(64);
    Math::MPFR::Rmpfr_mul_z($N, $K, $d, $round);
    Math::MPFR::Rmpfr_root($N, $N, $n - 1, $round);
    Math::MPFR::Rmpfr_ceil($N, $N);

    $N = Math::MPFR::Rmpfr_get_ui($N, $round);

    my $z = Math::MPFR::Rmpfr_init2($prec);
    my $t = Math::MPFR::Rmpfr_init2($prec);

    Math::MPFR::Rmpfr_set_ui($z, 1, $round);

#<<<
    for (my $p = Math::GMPz::Rmpz_init_set_ui(2) ;
         Math::GMPz::Rmpz_cmp_ui($p, $N) <= 0 ;
         Math::GMPz::Rmpz_nextprime($p, $p)
    ) {
        my $ui = Math::GMPz::Rmpz_get_ui($p);
        Math::MPFR::Rmpfr_ui_pow_ui($t, $ui, $n, $round);
        Math::MPFR::Rmpfr_ui_div($t, 1, $t, $round);
        Math::MPFR::Rmpfr_ui_sub($t, 1, $t, $round);
        Math::MPFR::Rmpfr_mul($z, $z, $t, $round);
    }
#>>>

    Math::MPFR::Rmpfr_ui_div($z, 1, $z, $round);

    Math::MPFR::Rmpfr_mul($z, $z, $K, $round);
    Math::MPFR::Rmpfr_mul_z($z, $z, $d, $round);

    Math::MPFR::Rmpfr_ceil($z, $z);

    my $q = Math::GMPq::Rmpq_init();

    Math::GMPq::Rmpq_set_den($q, $d);
    Math::MPFR::Rmpfr_get_z($d, $z, $round);
    Math::GMPz::Rmpz_neg($d, $d) if $n % 4 == 0;
    Math::GMPq::Rmpq_set_num($q, $d);

    return $q;
}

foreach my $i (0 .. 50) {
    printf "B%-3d = %s\n", 2 * $i, bern_from_primes(2 * $i);
}
