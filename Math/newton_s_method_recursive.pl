#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 18 July 2016
# Website: https://github.com/trizen

# Newton's method -- recursive

# x^(1/n) = f(k)    ; with k -> infinity.

# where f(k) is defined as:
# | f(1) = 1
# | f(k) = (f(k-1) * (n-1) + x / f(k-1)^(n-1)) / n

# Alternatively, f(k) can be defined as:
#  | f(1) = 1
#  | f(k) = (1 - 1/n) * f(k-1) + x / (n * f(k-1)^(n-1))

use 5.016;

sub nth_root {
    my ($n, $x, $k) = @_;

    my $p = $n - 1;

    sub {
        my $f = (
                 $_[0] > 1
                 ? __SUB__->($_[0] - 1)
                 : return 1
                );

        ($f * $p + $x / $f**$p) / $n;
      }
      ->($k);
}

say nth_root(2, 2,    100);    # square root of 2
say nth_root(3, 27,   100);    # third root of 27
say nth_root(3, 125,  100);    # third root of 125
say nth_root(5, 3125, 100);    # fifth root of 3125
