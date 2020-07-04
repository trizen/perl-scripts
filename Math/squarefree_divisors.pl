#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 08 July 2018
# https://github.com/trizen

# Generate the squarefree divisors of a given number.

# See also:
#   https://oeis.org/A048250

use 5.010;
use strict;
use warnings;

use ntheory qw(factor_exp);

sub squarefree_divisors {
    my ($n) = @_;

    my @d = (1);
    my @pp = map { $_->[0] } factor_exp($n);

    foreach my $p (@pp) {
        push @d, map { $_ * $p } @d;
    }

    return sort { $a <=> $b } @d;
}

foreach my $n (1 .. 30) {
    my @d = squarefree_divisors($n);
    say "a($n) = [@d]";
}
