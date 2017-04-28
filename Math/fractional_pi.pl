#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 10 May 2016
# Website: https://github.com/trizen

# Calculate PI by computing the numerator and the denominator fraction that approaches the value of PI.
# It's based on the continued fraction: n^2 / (2n+1)

# See: http://oeis.org/A054766
#      http://oeis.org/A054765

use 5.010;
use strict;
use warnings;

use Memoize qw(memoize);
use Math::AnyNum qw(:overload as_dec);

no warnings 'recursion';

memoize('pi_nu');
memoize('pi_de');

sub pi_nu {
    my ($n) = @_;
    $n < 2
      ? ($n == 0 ? 1 : 0)
      : (2 * $n - 1) * pi_nu($n - 1) + ($n - 1)**2 * pi_nu($n - 2);
}

sub pi_de {
    my ($n) = @_;
    $n < 2
      ? $n
      : (2 * $n - 1) * pi_de($n - 1) + ($n - 1)**2 * pi_de($n - 2);
}

my $prec = 1000;
my $pi = as_dec(4 / (1 + pi_nu($prec) / pi_de($prec)), int($prec / 1.32));
say $pi;
