#!/usr/bin/perl

# Author: Trizen
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

foreach my $n (1 .. 20) {
    my @d = squarefree_divisors($n);
    say "squarefree divisors of $n: [@d]";
}

__END__
squarefree divisors of 1: [1]
squarefree divisors of 2: [1 2]
squarefree divisors of 3: [1 3]
squarefree divisors of 4: [1 2]
squarefree divisors of 5: [1 5]
squarefree divisors of 6: [1 2 3 6]
squarefree divisors of 7: [1 7]
squarefree divisors of 8: [1 2]
squarefree divisors of 9: [1 3]
squarefree divisors of 10: [1 2 5 10]
squarefree divisors of 11: [1 11]
squarefree divisors of 12: [1 2 3 6]
squarefree divisors of 13: [1 13]
squarefree divisors of 14: [1 2 7 14]
squarefree divisors of 15: [1 3 5 15]
squarefree divisors of 16: [1 2]
squarefree divisors of 17: [1 17]
squarefree divisors of 18: [1 2 3 6]
squarefree divisors of 19: [1 19]
squarefree divisors of 20: [1 2 5 10]
