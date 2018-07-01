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

use ntheory qw(factor_exp);

sub unitary_squarefree_divisors {
    my ($n) = @_;

    my @d  = (1);
    my @pp = map { $_->[0] } grep { $_->[1] == 1 } factor_exp($n);

    foreach my $p (@pp) {
        push @d, map { $_ * $p } @d;
    }

    return sort { $a <=> $b } @d;
}

foreach my $n (1 .. 30) {
    my @d = unitary_squarefree_divisors($n);
    say "a($n) = [@d]";
}
