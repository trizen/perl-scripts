#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 08 July 2018
# https://github.com/trizen

# Generate the squarefree divisors of a given number.

# See also:
#   https://oeis.org/A048250

use 5.036;
use ntheory qw(:all);

sub squarefree_divisors($n) {

    my @d = (1);
    my @pp = map { $_->[0] } factor_exp($n);

    foreach my $p (@pp) {
        push @d, map { mulint($_, $p) } @d;
    }

    return sort { $a <=> $b } @d;
}

foreach my $n (1 .. 30) {
    my @d = squarefree_divisors($n);
    say "a($n) = [@d]";
}
