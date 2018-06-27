#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 27 June 2018
# https://github.com/trizen

# Generate the unitary squarefree divisors of a given number.

# See also:
#   https://oeis.org/A092261

use 5.010;
use strict;
use warnings;

use ntheory qw(factor_exp gcd);

sub unitary_squarefree_divisors {
    my ($n) = @_;

    my @factors = map { $_->[0] } factor_exp($n);

    my @d = (1);

    my %seen;
    while (my $p = shift(@factors)) {

        my @t;
        foreach my $d (@d) {
            if (gcd($n / ($p * $d), $p * $d) == 1) {
                push @t, $p * $d;
            }
        }

        push @d, @t;
    }

    return sort { $a <=> $b } @d;
}

foreach my $n (1 .. 30) {
    my @d = unitary_squarefree_divisors($n);
    say "a($n) = [@d]";
}
