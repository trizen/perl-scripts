#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 04 September 2015
# Website: https://github.com/trizen

# Compute the average of choosing a random prime number
# in a given range such as the difference between 2n
# and a prime number to be another prime number.
#
# Example:
#   is_prime(2n - rand_prime(2, 2n-2))   # true
#
# This problem is related to Goldbach conjecture.
# It shows that we have to choose, on average,
# log(n)/2 times a random prime number to satisfy
# the above property. This is an important outcome!

use 5.010;
use strict;
use warnings;

use ntheory qw(
    vecsum
    is_prime
    random_prime
);

my $max = 100000;

my @counts;
foreach my $i (2 .. $max) {
    my $n = 2 * $i;

    my $count = 0;
    while (1) {
        ++$count;
        last if is_prime($n - random_prime(2, $n - 2));
    }

    push @counts, $count;
}

say "Expected: ", log($max) / 2;
say "Observed: ", vecsum(@counts) / @counts;

__END__
--------------------------
  Example for max=300000
--------------------------
Expected: 6.30576887681917
Observed: 6.3850079500265
