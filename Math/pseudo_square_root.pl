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

use ntheory qw(factor sqrtint vecmax);

sub pseudo_square_root {
    my ($n) = @_;

    my $lim     = sqrtint($n);
    my @factors = grep { $_ <= $lim } factor($n);

    my @d = (1);

    my %seen;
    while (my $p = shift(@factors)) {
        my @t;
        foreach my $d (@d) {
            if ($p * $d <= $lim and !$seen{$p * $d}++) {
                push @t, $p * $d;
            }
        }
        push @d, @t;
    }

    return vecmax(@d);
}

say pseudo_square_root(479001600);     #=> 21600
say pseudo_square_root(6469693230);    #=> 79534
say pseudo_square_root(12398712476);   #=> 68
