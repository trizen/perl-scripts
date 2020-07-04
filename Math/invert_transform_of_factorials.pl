#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 03 December 2017
# https://github.com/trizen

# A new algorithm for computing the invert transform of factorial numbers.

# See also:
#   http://oeis.org/A051296

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(:overload factorial binomial);

sub invert_transform_of_factorials {
    my ($n) = @_;

    my @F = (1);

    foreach my $i (1 .. $n) {
        foreach my $k (0 .. $i - 1) {
            $F[$i] += $F[$k] / binomial($i, $k);
        }
    }

    map { $F[$_] * factorial($_) } 0 .. $#F;
}

my @F = invert_transform_of_factorials(20);

foreach my $i (0 .. $#F) {
    say "F($i) = $F[$i]";
}

__END__
F(0) = 1
F(1) = 1
F(2) = 3
F(3) = 11
F(4) = 47
F(5) = 231
F(6) = 1303
F(7) = 8431
F(8) = 62391
F(9) = 524495
F(10) = 4960775
F(11) = 52223775
F(12) = 605595319
F(13) = 7664578639
F(14) = 105046841127
F(15) = 1548880173119
F(16) = 24434511267863
F(17) = 410503693136559
F(18) = 7315133279097607
F(19) = 137787834979031839
F(20) = 2734998201208351479
