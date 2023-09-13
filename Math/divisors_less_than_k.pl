#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 04 August 2019
# https://github.com/trizen

# Generate all the divisors d of n, such that d <= k.

use 5.010;
use strict;
use warnings;

use ntheory qw(factor_exp divisors);

sub divisors_le {
    my ($n, $k) = @_;

    my @d  = (1);
    my @pp = grep { $_->[0] <= $k } factor_exp($n);

    foreach my $pp (@pp) {

        my ($p, $e) = @$pp;

        my @t;
        my $r = 1;

        for my $i (1 .. $e) {
            $r *= $p;
            foreach my $u (@d) {
                push(@t, $u * $r) if ($u * $r <= $k);
            }
        }

        push @d, @t;
    }

    return sort { $a <=> $b } @d;
}

# Generate the divisors of 5040 less than or equal to 42
say join ' ', divisors_le(5040, 42);
