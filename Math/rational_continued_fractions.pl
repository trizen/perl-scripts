#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 31 July 2016
# Website: https://github.com/trizen

# Recursive evaluation of continued fractions rationally,
# by computing the numerator and the denominator individually.

# For every continued fraction, we have the following relation:
#
#    n
#   | / a(k)    kn(n)
#   |/ ----- = -------
#   | \ b(k)    kd(n)
#   k=0

use 5.010;
use strict;
use warnings;

use Memoize qw(memoize);

no warnings qw(recursion);
use experimental qw(signatures);

memoize('kn');
memoize('kd');

sub a($n) {
    $n**2;
}

sub b($n) {
    2 * $n + 1;
}

sub kn($n) {
    $n < 2
      ? ($n == 0 ? 1 : 0)
      : b($n - 1) * kn($n - 1) + a($n - 1) * kn($n - 2);
}

sub kd($n) {
    $n < 2
      ? $n
      : b($n - 1) * kd($n - 1) + a($n - 1) * kd($n - 2);
}

for my $i (0 .. 10) {
    printf("%2d. %20d %20d\n", $i, kn($i), kd($i));
}
