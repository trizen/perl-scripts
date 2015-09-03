#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use bigrat (try => 'GMP');

# Translation of:
#   https://en.wikipedia.org/wiki/Bernoulli_number#Algorithmic_description

sub bernoulli_number {
    my ($n) = @_;

    my @A;
    for my $m (0 .. $n) {
        $A[$m] = 1 / ($m + 1);

        for (my $j = $m ; $j > 0 ; $j--) {
            $A[$j - 1] = $j * ($A[$j - 1] - $A[$j]);
        }
    }

    return $A[0];
}

foreach my $i (0 .. 10) {
    say "$i: ", bernoulli_number($i);
}

__END__
0: 1
1: 1/2
2: 1/6
3: 0
4: -1/30
5: 0
6: 1/42
7: 0
8: -1/30
9: 0
10: 5/66
