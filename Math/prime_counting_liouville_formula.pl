#!/usr/bin/perl

# Author: Trizen
# Date: 17 July 2025
# https://github.com/trizen

# A sublinear algorithm for computing the Prime Counting function `pi(n)`,
# based on the Liouville function and the number of k-almost primes <= n, for `k >= 2`.

# See also:
#   https://en.wikipedia.org/wiki/Mertens_function
#   https://en.wikipedia.org/wiki/M%C3%B6bius_function

use 5.036;
use ntheory qw(:all);

sub k_prime_count ($k, $n) {

    if ($k == 1) {
        return my_prime_count($n);
    }

    my $count = 0;

    sub ($m, $p, $k, $j = 0) {

        my $s = rootint(divint($n, $m), $k);

        if ($k == 2) {

            forprimes {
                $count += my_prime_count(divint($n, mulint($m, $_))) - $j++;
            } $p, $s;

            return;
        }

        foreach my $q (@{primes($p, $s)}) {
            __SUB__->($m * $q, $q, $k - 1, $j++);
        }
    }->(1, 2, $k);

    return $count;
}

sub my_prime_count ($n) {

    state $pi_table = [0, 0, 1, 2, 2];      # a larger lookup table helps a lot!

    if ($n < 0) {
        return 0;
    }

    if (defined($pi_table->[$n])) {
        return $pi_table->[$n];
    }

    my $M = sumliouville($n);

    foreach my $k (2 .. logint($n, 2)) {
        $M -= (-1)**$k * k_prime_count($k, $n);
    }

    return ($pi_table->[$n] //= 1 - $M);
}

foreach my $n (1..7) {    # takes ~3 seconds
    say "pi(10^$n) = ", my_prime_count(10**$n);
}

__END__
pi(10^1) = 4
pi(10^2) = 25
pi(10^3) = 168
pi(10^4) = 1229
pi(10^5) = 9592
pi(10^6) = 78498
pi(10^7) = 664579
