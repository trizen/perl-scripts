#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 17 June 2017
# https://github.com/trizen

# Finds a close-enough fraction to a given decimal expansion.

use 5.014;
use strict;
use warnings;

use Test::More;
plan tests => 3;

sub decimal_to_rational {
    my ($dec) = @_;

    for (my $n = int($dec) + 1 ; ; ++$n) {
        my $m = int($n / $dec) || next;
        if (index($n / $m, $dec) == 0) {
            return "$n/$m";
        }
    }
}

is(decimal_to_rational('1.008155930329'),  '7293/7234');
is(decimal_to_rational('1.0019891835756'), '524875/523833');
is(decimal_to_rational('529.12424242424'), '174611/330');
