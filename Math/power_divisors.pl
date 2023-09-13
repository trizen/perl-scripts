#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 17 August 2021
# https://github.com/trizen

# Generate all the k-th power divisors of a given number.

use 5.036;
use ntheory qw(:all);

sub power_divisors ($n, $k=1) {

    my @d = (1);
    my @pp = grep { $_->[1] >= $k } factor_exp($n);

    foreach my $pp (@pp) {
        my ($p, $e) = @$pp;

        my @t;
        for (my $i = $k ; $i <= $e ; $i += $k) {
            my $u = powint($p, $i);
            push @t, map { mulint($_, $u) } @d;
        }

        push @d, @t;
    }

    sort { $a <=> $b } @d;
}

say join(', ', power_divisors(3628800, 2));     # square divisors
say join(', ', power_divisors(3628800, 3));     # cube divisors
say join(', ', power_divisors(3628800, 4));     # 4th power divisors
