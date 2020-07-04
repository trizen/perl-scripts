#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 25 January 2019
# License: GPLv3
# https://github.com/trizen

# Compute the period length of the continued fraction for square root of a given number.

# Algorithm from:
#   http://web.math.princeton.edu/mathlab/jr02fall/Periodicity/mariusjp.pdf

# OEIS sequences:
#   https://oeis.org/A003285 -- Period of continued fraction for square root of n (or 0 if n is a square).
#   https://oeis.org/A059927 -- Period length of the continued fraction for sqrt(2^(2n+1)).
#   https://oeis.org/A064932 -- Period length of the continued fraction for sqrt(3^(2n+1)).
#   https://oeis.org/A067280 -- Terms in continued fraction for sqrt(n), excl. 2nd and higher periods.
#   https://oeis.org/A064025 -- Length of period of continued fraction for square root of n!.
#   https://oeis.org/A064486 -- Quotient cycle lengths of square roots of primorials.

# See also:
#   https://en.wikipedia.org/wiki/Continued_fraction
#   http://mathworld.wolfram.com/PeriodicContinuedFraction.html

# A064486 = {1, 2, 2, 2, 2, 4, 2, 36, 38, 244, 244, 1830, 3422, 10626, 3828, 20970, 580384, 4197850, 18395762, 76749396, 166966158, ...}
# A064025 = {1, 2, 2, 2, 4, 2, 16, 48, 8, 4, 56, 180, 44, 156, 300, 7936, 10388, 11516, 9104, 13469268, 2684084, 2418800, 28468692, 143007944, 85509116, 402570696, ...}

use 5.010;
use strict;
use warnings;

use Math::GMPz;
use ntheory qw(factorial);

sub period_length_mpz {
    my ($n) = @_;

    $n = Math::GMPz->new("$n");

    return 0 if Math::GMPz::Rmpz_perfect_square_p($n);

    my $t = Math::GMPz::Rmpz_init();
    my $x = Math::GMPz::Rmpz_init();
    my $z = Math::GMPz::Rmpz_init_set_ui(1);

    Math::GMPz::Rmpz_sqrt($x, $n);

    my $y = Math::GMPz::Rmpz_init_set($x);

    my $period = 0;

    do {
        Math::GMPz::Rmpz_add($t, $x, $y);
        Math::GMPz::Rmpz_div($t, $t, $z);
        Math::GMPz::Rmpz_mul($t, $t, $z);
        Math::GMPz::Rmpz_sub($y, $t, $y);

        Math::GMPz::Rmpz_mul($t, $y, $y);
        Math::GMPz::Rmpz_sub($t, $n, $t);
        Math::GMPz::Rmpz_divexact($z, $t, $z);

        ++$period;

    } until (Math::GMPz::Rmpz_cmp_ui($z, 1) == 0);

    return $period;
}

foreach my $n (1..20) {
    say "A064025($n) = ", period_length_mpz(factorial($n));
}
