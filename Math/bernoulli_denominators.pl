#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13 May 2017
# https://github.com/trizen

# Fast computation of the denominator of the nth-Bernoulli number.

use 5.010;
use strict;
use warnings;

use Math::GMPz;
use POSIX qw(ULONG_MAX);
use ntheory qw(fordivisors is_prob_prime);

sub bernoulli_denominator {
    my ($n) = @_;

    my $p = Math::GMPz::Rmpz_init();
    my $d = Math::GMPz::Rmpz_init_set_ui(1);

    fordivisors {
        if ($_ >= ULONG_MAX) {
            Math::GMPz::Rmpz_set_str($p, "$_", 10);
            Math::GMPz::Rmpz_add_ui($p, $p, 1);

            if (is_prob_prime($p)) {
                Math::GMPz::Rmpz_mul($d, $d, $p);
            }
        }
        else {
            if (is_prob_prime($_ + 1)) {
                Math::GMPz::Rmpz_mul_ui($d, $d, $_ + 1);    # d = d * p, where (p-1)|n
            }
        }
    } $n;

    return $d;
}

foreach my $n (1 .. 20) {
    say "B_denom(10^$n) = ", bernoulli_denominator('1' . ('0' x $n));
}
