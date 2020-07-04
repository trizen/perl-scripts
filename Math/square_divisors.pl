#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 30 July 2018
# https://github.com/trizen

# Generate all the square divisors of a given number.

use 5.010;
use strict;
use warnings;

use ntheory qw(factor_exp);

sub square_divisors {
    my ($n) = @_;

    my @d = (1);
    my @pp = grep { $_->[1] > 1 } factor_exp($n);

    foreach my $pp (@pp) {
        my $p = $pp->[0];
        my $e = $pp->[1];

        my @t;
        for (my $i = 2 ; $i <= $e ; $i += 2) {
            push @t, map { $_ * $p**$i } @d;
        }

        push @d, @t;
    }

    return sort { $a <=> $b } @d;
}

say join(', ', square_divisors(3628800));
