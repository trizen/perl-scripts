#!/usr/bin/perl

# Algorithm for computing the secant numbers (also known as Euler numbers):
#
#   1, 1, 5, 61, 1385, 50521, 2702765, 199360981, 19391512145, 2404879675441, 370371188237525, ...
#

# Algorithm presented in the book:
#
#   Modern Computer Arithmetic
#           - by Richard P. Brent and Paul Zimmermann
#

# See also:
#   https://oeis.org/A000364
#   https://en.wikipedia.org/wiki/Euler_number

use 5.010;
use strict;
use warnings;

use Math::GMPz;

sub secant_numbers {
    my ($n) = @_;

    my @S = (Math::GMPz::Rmpz_init_set_ui(1));

    foreach my $k (1 .. $n) {
        Math::GMPz::Rmpz_mul_ui($S[$k] = Math::GMPz::Rmpz_init(), $S[$k - 1], $k);
    }

    foreach my $k (1 .. $n) {
        foreach my $j ($k + 1 .. $n) {
            Math::GMPz::Rmpz_addmul_ui($S[$j], $S[$j - 1], ($j - $k + 2) * ($j - $k));
        }
    }

    return @S;
}

say join(', ', secant_numbers(10));
