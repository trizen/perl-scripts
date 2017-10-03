#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 03 October 2017
# https://github.com/trizen

# A simple implementation of the multivariate gamma function.

# See also:
#   https://en.wikipedia.org/wiki/Multivariate_gamma_function

use 5.014;
use warnings;

use Math::AnyNum qw(pi gamma);

sub multivariate_gamma {
    my ($n, $p) = @_;

    my $prod = 1;
    foreach my $j (1 .. $p) {
        $prod *= gamma($n + (1 - $j) / 2);
    }

    $prod * pi**($p * ($p - 1) / 4);
}

say multivariate_gamma(10, 5);    # means: gamma_5(10)
