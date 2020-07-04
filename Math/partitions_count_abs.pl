#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 26 April 2017
# Website: https://github.com/trizen

# Simple counting of the number of partitions of n that
# absolutely sum to n, in the range [-n, n], excluding 0.

# See also:
#   https://oeis.org/A000041

use 5.016;
use strict;
use warnings;
use Memoize qw(memoize);

no warnings 'recursion';

my $atoms;
sub partitions_count_abs {
    my ($n, $i, $sum) = @_;

        (abs($sum) == $n)                   ? 1
      : (abs($sum) > $n || $i > $#{$atoms}) ? 0
      : ( partitions_count_abs($n, $i, $sum + $atoms->[$i])
        + partitions_count_abs($n, $i + 1, $sum));
}

memoize('partitions_count_abs');

foreach my $n (1 .. 20) {
    $atoms = [grep { $_ != 0 } (-$n .. $n)];
    say "P($n) = ", partitions_count_abs($n, 0, 0);
}

__END__
P(1) = 2
P(2) = 6
P(3) = 20
P(4) = 67
P(5) = 219
P(6) = 637
P(7) = 1823
P(8) = 4748
P(9) = 12045
P(10) = 28875
P(11) = 67320
P(12) = 150137
P(13) = 328849
P(14) = 694865
P(15) = 1441493
P(16) = 2915967
P(17) = 5800757
P(18) = 11292100
P(19) = 21683942
P(20) = 40885671
