#!/usr/bin/perl

# Algorithm for computing the tangent numbers:
#
#   1, 2, 16, 272, 7936, 353792, 22368256, 1903757312, 209865342976, 29088885112832, ...
#

# Algorithm presented in the book:
#
#   Modern Computer Arithmetic
#           - by Richard P. Brent and Paul Zimmermann
#

# See also:
#   https://oeis.org/A000182
#   https://mathworld.wolfram.com/TangentNumber.html
#   https://en.wikipedia.org/wiki/Alternating_permutation

use 5.010;
use strict;
use warnings;

use Math::GMPz;

sub tangent_numbers {
    my ($n) = @_;

    my @T = (Math::GMPz::Rmpz_init_set_ui(1));

    foreach my $k (1 .. $n - 1) {
        Math::GMPz::Rmpz_mul_ui($T[$k] = Math::GMPz::Rmpz_init(), $T[$k - 1], $k);
    }

    foreach my $k (1 .. $n - 1) {
        foreach my $j ($k .. $n - 1) {
            Math::GMPz::Rmpz_mul_ui($T[$j], $T[$j], $j - $k + 2);
            Math::GMPz::Rmpz_addmul_ui($T[$j], $T[$j - 1], $j - $k);

        }
    }

    return @T;
}

say join(', ', tangent_numbers(10));
