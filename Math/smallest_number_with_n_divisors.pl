#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 15 May 2021
# https://github.com/trizen

# Generate the smallest number that has exactly n divisors.

# See also:
#   https://oeis.org/A005179 -- Smallest number with exactly n divisors.

use 5.020;
use warnings;
use experimental qw(signatures);

use ntheory qw(nth_prime);
use Math::AnyNum qw(:overload);

sub smallest_number_with_n_divisors ($threshold, $least_solution = Inf, $k = 1, $max_a = Inf, $sigma0 = 1, $n = 1) {

    if ($sigma0 == $threshold) {
        return $n;
    }

    if ($sigma0 > $threshold) {
        return $least_solution;
    }

    my $p = nth_prime($k);

    for (my $a = 1 ; $a <= $max_a ; ++$a) {
        $n *= $p;
        last if ($n > $least_solution);
        $least_solution = __SUB__->($threshold, $least_solution, $k + 1, $a, $sigma0 * ($a + 1), $n);
    }

    return $least_solution;
}

say smallest_number_with_n_divisors(60);      #=> 5040
say smallest_number_with_n_divisors(1000);    #=> 810810000
