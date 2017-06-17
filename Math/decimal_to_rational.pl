#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 17 June 2017
# https://github.com/trizen

# Finds the smallest fraction approximation to a given decimal expansion.

use 5.014;
use strict;
use warnings;

use ntheory qw(gcd);

use Test::More;
plan tests => 4;

sub decimal_to_rational {
    my ($dec) = @_;

    for (my $n = int($dec) + 1 ; ; ++$n) {

        my ($num, $den) =
          $dec > 1
          ? (sprintf('%.0f', $n * $dec), $n)
          : ($n, sprintf('%.0f', $n / $dec));

        if ($den and index($num / $den, $dec) == 0) {
            my $gcd = gcd($num, $den);
            return join('/', $num / $gcd, $den / $gcd);
        }
    }
}

is(decimal_to_rational('0.6180339887'),    '75025/121393');
is(decimal_to_rational('1.008155930329'),  '7293/7234');
is(decimal_to_rational('1.0019891835756'), '524875/523833');
is(decimal_to_rational('529.12424242424'), '174611/330');
