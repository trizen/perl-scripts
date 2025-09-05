#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 27 August 2025
# https://github.com/trizen

# A sublinear algorithm for computing the Prime Counting function `pi(n)`,
# based on the number of squarefree k-almost primes <= n, for `k >= 2`, which can be computed in sublinear time.

# See also:
#   https://mathworld.wolfram.com/AlmostPrime.html

use 5.036;
use ntheory qw(:all);

sub squarefree_almost_prime_count ($k, $n) {

    if ($k == 0) {
        return (($n <= 0) ? 0 : 1);
    }

    if ($k == 1) {
        return my_prime_count($n);
    }

    my $count = 0;

    sub ($m, $p, $k, $j = 1) {

        my $s = rootint(divint($n, $m), $k);

        if ($k == 2) {

            forprimes {
                $count += my_prime_count(divint($n, mulint($m, $_))) - $j++;
            }
            $p, $s;

            return;
        }

        foreach my $q (@{primes($p, $s)}) {
            __SUB__->(mulint($m, $q), $q + 1, $k - 1, ++$j);
        }
      }
      ->(1, 2, $k);

    return $count;
}

sub my_prime_count ($n) {

    state %cache = (    # a larger lookup table helps a lot!
                     0 => 0,
                     1 => 0,
                     2 => 1,
                     3 => 2,
                     4 => 2,
                   );

    if ($n < 0) {
        return 0;
    }

    if (exists $cache{$n}) {
        return $cache{$n};
    }

    my $M = powerfree_count($n, 2) - 1;

    foreach my $k (2 .. exp(LambertW(log($n))) + 1) {
        $M -= squarefree_almost_prime_count($k, $n);
    }

    $cache{$n} //= $M;
}

foreach my $n (1 .. 7) {    # takes ~1 second
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
