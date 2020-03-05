#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 18 August 2017
# https://github.com/trizen

# Find the greatest divisor of `n` that does not exceed the square root of `n`.

# See also:
#   https://projecteuler.net/problem=266

use 5.010;
use strict;
use warnings;

use ntheory qw(factor_exp sqrtint vecmax);

sub pseudo_square_root {
    my ($n) = @_;

    my $limit = sqrtint($n);

    my @d  = (1);
    my @pp = grep { $_->[0] <= $limit } factor_exp($n);

    foreach my $pp (@pp) {

        my $p = $pp->[0];
        my $e = $pp->[1];

        my @t;
        my $r = 1;

        for my $i (1 .. $e) {
            $r *= $p;
            foreach my $u (@d) {
                push(@t, $u * $r) if ($u * $r <= $limit);
            }
        }

        push @d, @t;
    }

    return vecmax(@d);
}

say pseudo_square_root(479001600);     #=> 21600
say pseudo_square_root(6469693230);    #=> 79534
say pseudo_square_root(12398712476);   #=> 68
