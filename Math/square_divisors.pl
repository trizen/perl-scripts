#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 30 July 2018
# https://github.com/trizen

# Generate all the square divisors of a given number.

use 5.036;
use ntheory qw(:all);

sub square_divisors($n) {

    my @d = (1);
    my @pp = grep { $_->[1] > 1 } factor_exp($n);

    foreach my $pp (@pp) {
        my ($p, $e) = @$pp;

        my @t;
        for (my $i = 2 ; $i <= $e ; $i += 2) {
            my $u = powint($p, $i);
            push @t, map { mulint($_, $u) } @d;
        }

        push @d, @t;
    }

    return sort { $a <=> $b } @d;
}

say join(', ', square_divisors(3628800));
