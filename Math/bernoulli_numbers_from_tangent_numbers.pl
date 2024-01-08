#!/usr/bin/perl

# Algorithm for computing the Bernoulli numbers from the tangent numbers.

# Algorithm presented in the book:
#
#   Modern Computer Arithmetic
#           - by Richard P. Brent and Paul Zimmermann
#

# See also:
#   https://oeis.org/A000182
#   https://mathworld.wolfram.com/TangentNumber.html
#   https://en.wikipedia.org/wiki/Alternating_permutation
#   https://en.wikipedia.org/wiki/Bernoulli_number

use 5.010;
use strict;
use warnings;

use Math::GMPz;
use Math::GMPq;

sub bernoulli_number {
    my ($N) = @_;

    my $q = Math::GMPq::Rmpq_init();

    if ($N == 0) {
        Math::GMPq::Rmpq_set_ui($q, 1, 1);
        return $q;
    }

    if ($N == 1) {
        Math::GMPq::Rmpq_set_si($q, -1, 2);
        return $q;
    }

    if ($N & 1) {
        Math::GMPq::Rmpq_set_ui($q, 0, 1);
        return $q;
    }

    my $n = ($N >> 1) - 1;
    my @T = (Math::GMPz::Rmpz_init_set_ui(1));

    foreach my $k (1 .. $n) {
        Math::GMPz::Rmpz_mul_ui($T[$k] = Math::GMPz::Rmpz_init(), $T[$k - 1], $k);
    }

    foreach my $k (1 .. $n) {
        foreach my $j ($k .. $n) {
            Math::GMPz::Rmpz_mul_ui($T[$j], $T[$j], $j - $k + 2);
            Math::GMPz::Rmpz_addmul_ui($T[$j], $T[$j - 1], $j - $k);
        }
    }

    my $t = $T[-1];
    Math::GMPz::Rmpz_mul_ui($t, $t, $N);
    Math::GMPz::Rmpz_neg($t, $t) if ($n & 1);
    Math::GMPq::Rmpq_set_z($q, $t);

    # z = (2^n - 1) * 2^n
    my $z = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_setbit($z, $N);
    Math::GMPz::Rmpz_sub_ui($z, $z, 1);
    Math::GMPz::Rmpz_mul_2exp($z, $z, $N);

    Math::GMPq::Rmpq_div_z($q, $q, $z);

    return $q;
}

foreach my $n (1 .. 50) {
    printf("B(%s) = %s\n", 2 * $n, bernoulli_number(2 * $n));
}
