#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 04 September 2015
# Website: https://github.com/trizen

# Goldbach conjecture as the sum of two primes
# with one prime being in the range of (n, 2n)

# Proving that always there is a prime number between
# n and 2n which can be added with a smaller prime
# such as the sum is 2n, would prove the conjecture.

use 5.010;
use strict;
use warnings;

use List::Util qw(sum);
use ntheory qw(random_prime is_prime);

my $max = 10000;

my @counts;
foreach my $i (2 .. $max) {
    my $n = 2 * $i;

    my $count = 0;
    while (1) {
        ++$count;
        last if is_prime($n - random_prime($i, $n));
    }

    push @counts, $count;
}

say "Expected: ", log($max) / 2;
say "Observed: ", sum(@counts) / @counts;

__END__
--------------------------
  Example for max=1000000
--------------------------
Expected: 6.90775527898214
Observed: 6.66289466289466
