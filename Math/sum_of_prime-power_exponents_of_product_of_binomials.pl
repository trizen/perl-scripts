#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 15 January 2019
# https://github.com/trizen

# Program for computing the sum of the exponents in prime-power factorization of Product_{k=0..n} binomial(n, k).

#~ a(10^1) = 33
#~ a(10^2) = 1847
#~ a(10^3) = 94677
#~ a(10^4) = 6344339
#~ a(10^5) = 481640842
#~ a(10^6) = 39172738473
#~ a(10^7) = 3310162914057

# See also:
#   https://oeis.org/A323444

# Paper:
#   Jeffrey C. Lagarias, Harsh Mehta
#   Products of binomial coefficients and unreduced Farey fractions
#   http://arxiv.org/abs/1409.4145

use 5.010;
use strict;
use warnings;

use ntheory qw(factor);

sub sum_of_exponents_of_product_of_binomials {
    my ($n) = @_;

    return 0 if ($n <= 1);

    my ($r, $t) = (0, 0);

    foreach my $k (1 .. $n) {
        my $z = factor($k);
        $t += $z;
        $r += $k * $z - $t;
    }

    return $r;
}

foreach my $k (1 .. 7) {
    say "a(10^$k) = ", sum_of_exponents_of_product_of_binomials(10**$k);
}
