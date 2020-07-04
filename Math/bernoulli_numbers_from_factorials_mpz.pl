#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 07 July 2018
# https://github.com/trizen

# A new algorithm for computing Bernoulli numbers.

# Inspired from Norman J. Wildberger video lecture:
#   https://www.youtube.com/watch?v=qmMs6tf8qZ8

# See also:
#   https://en.wikipedia.org/wiki/Bernoulli_number#Connection_with_Pascal’s_triangle

use 5.010;
use strict;
use warnings;

use Math::GMPq;
use Math::GMPz;

sub bernoulli_numbers {
    my ($n) = @_;

    my @A = (Math::GMPz::Rmpz_init_set_ui(1));
    my @B = (Math::GMPz::Rmpz_init_set_ui(1));
    my @F = (Math::GMPz::Rmpz_init_set_ui(1));

    foreach my $k (1 .. $n) {

        $F[$k] = Math::GMPz::Rmpz_init();
        $A[$k] = Math::GMPz::Rmpz_init_set_ui(0);
        $B[$k] = Math::GMPz::Rmpz_init_set_ui(1);

        Math::GMPz::Rmpz_mul_ui($F[$k], $F[$k - 1], $k);
    }

    Math::GMPz::Rmpz_mul_ui($F[$n + 1] = Math::GMPz::Rmpz_init(), $F[$n], $n + 1);

    my $t = Math::GMPz::Rmpz_init();

    foreach my $i (1 .. $n) {

        if ($i % 2 != 0 and $i > 1) {
            next;
        }

        foreach my $k (0 .. $i - 1) {

            if ($k % 2 != 0 and $k > 1) {
                next;
            }

            my $r = $i - $k + 1;

            Math::GMPz::Rmpz_mul($A[$i], $A[$i], $F[$r]);
            Math::GMPz::Rmpz_mul($A[$i], $A[$i], $B[$k]);
            Math::GMPz::Rmpz_submul($A[$i], $B[$i], $A[$k]);
            Math::GMPz::Rmpz_mul($B[$i], $B[$i], $F[$r]);
            Math::GMPz::Rmpz_mul($B[$i], $B[$i], $B[$k]);

            Math::GMPz::Rmpz_gcd($t, $A[$i], $B[$i]);
            Math::GMPz::Rmpz_divexact($A[$i], $A[$i], $t);
            Math::GMPz::Rmpz_divexact($B[$i], $B[$i], $t);
        }
    }

    my @R = @A;

    for (my $k = 2 ; $k <= $#B ; $k += 2) {
        Math::GMPz::Rmpz_mul($A[$k], $A[$k], $F[$k]);

        my $bern = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_num($bern, $A[$k]);
        Math::GMPq::Rmpq_set_den($bern, $B[$k]);
        Math::GMPq::Rmpq_canonicalize($bern);

        $R[$k] = $bern;
    }

    if ($#R > 0) {
        my $bern = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_num($bern, $A[1]);
        Math::GMPq::Rmpq_set_den($bern, $B[1]);
        Math::GMPq::Rmpq_canonicalize($bern);
        $R[1] = $bern;
    }

    return @R;
}

my @B = bernoulli_numbers(100);    # first 100 Bernoulli numbers

foreach my $i (0 .. $#B) {
    say "B($i) = $B[$i]";
}
