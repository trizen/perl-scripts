#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Math::BigNum qw(:constant);

# Translation of:
#   https://en.wikipedia.org/wiki/Bernoulli_number#Algorithmic_description

sub bernoulli_number {
    my ($n) = @_;

    return 0 if $n > 1 && $n % 2;    # Bn = 0 for all odd n > 1

    my @A;
    for my $m (0 .. $n) {
        $A[$m] = 1 / ($m + 1);

        for (my $j = $m ; $j > 0 ; $j--) {
            $A[$j - 1] = $j * ($A[$j - 1] - $A[$j]);
        }
    }

    return $A[0];                    # which is Bn
}

foreach my $i (0 .. 20) {
    say "$i: ", bernoulli_number($i)->as_rat;
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
11: 0
12: -691/2730
13: 0
14: 7/6
15: 0
16: -3617/510
17: 0
18: 43867/798
19: 0
20: -174611/330
