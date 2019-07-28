#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 10 January 2019
# https://github.com/trizen

# Perl program for efficiently computing terms of A277341:
#   https://oeis.org/A277341

# A277341(n) is the nearest integer to prime(n)^prime(n+1)/prime(n+1)^prime(n).

use 5.010;
use strict;
use warnings;

use Math::GMPz;
use Math::GMPq;

use ntheory qw(nth_prime next_prime prime_count);

my $z1 = Math::GMPz->new(1);
my $z2 = Math::GMPz->new(1);

my $q = Math::GMPq->new(1);

my $zt1 = Math::GMPz->new(1);
my $zt2 = Math::GMPz->new(1);

sub round {
    my ($n) = @_;

    Math::GMPz::Rmpz_set_q($zt1, $n);
    Math::GMPz::Rmpz_set($zt2, $zt1);

    Math::GMPq::Rmpq_mul_2exp($n, $n, 1);

    Math::GMPz::Rmpz_mul_2exp($zt1, $zt1, 1);
    Math::GMPz::Rmpz_add_ui($zt1, $zt1, 1);

    if (Math::GMPq::Rmpq_cmp_z($n, $zt1) < 0) {
        return $zt2;
    }

    Math::GMPz::Rmpz_add_ui($zt2, $zt2, 1);
    return $zt2;
}

my $from = nth_prime(1);       # start from this prime
my $to   = nth_prime(1000);    # end at this prime

foreach my $n (prime_count($from) .. prime_count($to)) {    # compute the first 1000 terms

    my $t0 = $from;
    my $t1 = next_prime($from);

    Math::GMPz::Rmpz_ui_pow_ui($z1, $t0, $t1);
    Math::GMPz::Rmpz_ui_pow_ui($z2, $t1, $t0);

    Math::GMPq::Rmpq_set_num($q, $z1);
    Math::GMPq::Rmpq_set_den($q, $z2);

    say $n, " ", round($q);

    $from = $t1;
}
