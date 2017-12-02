#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 02 December 2017
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

    my @B;
    my @factorial;

    Math::GMPq::Rmpq_set_ui($B[0]  = Math::GMPq::Rmpq_init(), 1, 1);
    Math::GMPq::Rmpq_set_ui($B[$_] = Math::GMPq::Rmpq_init(), 0, 1) for (1 .. $n);

    my $t = Math::GMPq::Rmpq_init();

    foreach my $i (1 .. $n) {
        foreach my $k (0 .. $i - 1) {

            if ($i % 2 != 0 and $i > 1) {
                next;
            }

            my $r = $i - $k + 1;

            $factorial[$r] //= do {
                my $t = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_fac_ui($t, $r);
                $t;
            };

            Math::GMPq::Rmpq_div_z($t, $B[$k], $factorial[$r]);
            Math::GMPq::Rmpq_sub($B[$i], $B[$i], $t);
        }
    }

    for (my $k = 2; $k <= $#B; $k += 2) {
        Math::GMPq::Rmpq_mul_z($B[$k], $B[$k], $factorial[$k]);
    }

    return @B;
}

my @B = bernoulli_numbers(100);    # first 100 Bernoulli numbers

foreach my $i (0 .. $#B) {
    say "B($i) = $B[$i]";
}
