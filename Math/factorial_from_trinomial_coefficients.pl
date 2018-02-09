#!/usr/bin/perl

# An efficient algorithm for computing n! using trinomial coefficients.

# See also:
#   http://oeis.org/A056040
#   https://oeis.org/A000142/a000142.pdf

use 5.020;
use strict;
use warnings;

use Math::GMPz;
use experimental qw(signatures);

sub trinomial {
    my ($m, $n, $o) = @_;

    my $prod = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_bin_uiui($prod, $m + $n + $o, $o);

    if ($n) {
        my $t = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_bin_uiui($t, $m + $n, $n);
        Math::GMPz::Rmpz_mul($prod, $prod, $t);
    }

    return $prod;
}

sub Factorial($n) {
    return 1 if ($n < 2);
    Factorial($n >> 1)**2 * trinomial(int($n / 2), $n % 2, int($n / 2));
}

foreach my $n (0 .. 30) {
    say "$n! = ", Factorial($n);
}
