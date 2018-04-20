#!/usr/bin/perl

# Daniel "Trizen" Șuteu and M. F. Hasler
# Date: 20 April 2018
# https://github.com/trizen

# Find the first index of the odd prime number in the nth-order Fibonacci sequence.

# See also:
#   https://oeis.org/A302990

use 5.020;
use strict;
use warnings;

use Math::GMPz;

my $ONE = Math::GMPz->new(1);

use ntheory qw(is_prob_prime);
use experimental qw(signatures);

sub kth_order_fibonacci ($k, $n = 2) {

    # Algorithm after M. F. Hasler from https://oeis.org/A302990
    my @a = map { $_ < $n ? ($ONE << $_) : $ONE } 1 .. ($n + 1);

    for (my $i = 2 * ($n += 1) - 2 ; $i <= $k ; ++$i) {
        $a[$i % $n] = ($a[($i - 1) % $n] << 1) - $a[$i % $n];
    }

    return @a;
}

sub find_kth_order_fibonacci_odd_prime ($k, $r = 0) {

    my $t = $k + 1;

    for (my $n = $r * $t ; ; $n += $t) {

        # say "Testing: $n";

        my @a = kth_order_fibonacci($n, $k);

        if (is_prob_prime($a[-2])) {
            # say("[second] Found: $n -> ", $k + $n - 1, ' -> ', $n - 2);
            return $n - 2;
        }

        if (is_prob_prime($a[-1])) {
            # say("[first] Found: $n -> ", $k + $n - 1, ' -> ', $n - 1);
            return $n - 1;
        }
    }
}

# Example for computing the terms a(2)-a(26) terms
say join ", ", map{ find_kth_order_fibonacci_odd_prime($_) } 2..26;

# Searching for a(33)
# say find_kth_order_fibonacci_odd_prime(33, int(84490 / 34));
