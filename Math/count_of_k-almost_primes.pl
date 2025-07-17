#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 22 May 2020
# https://github.com/trizen

# Count the number of k-almost primes <= n.

# Definition:
#   A number is k-almost prime if it is the product of k prime numbers (not necessarily distinct).
#   In other works, a number n is k-almost prime iff: bigomega(n) = k.

# See also:
#   https://mathworld.wolfram.com/AlmostPrime.html

# OEIS:
#   https://oeis.org/A072000 -- count of 2-almost primes
#   https://oeis.org/A072114 -- count of 3-almost primes
#   https://oeis.org/A082996 -- count of 4-almost primes
#   https://oeis.org/A126280 -- Triangle read by rows: T(k,n) is number of numbers <= 10^n that are products of k primes.

use 5.036;
use ntheory qw(:all);

sub k_prime_count ($n, $k) {

    if ($k == 1) {
        return prime_count($n);
    }

    if ($k == 2) {
        return semiprime_count($n);
    }

    my $count = 0;

    sub ($m, $p, $k, $j = 0) {

        my $s = rootint(divint($n, $m), $k);

        if ($k == 2) {

            forprimes {
                $count += prime_count(divint($n, mulint($m, $_))) - $j++;
            } $p, $s;

            return;
        }

        foreach my $q (@{primes($p, $s)}) {
            __SUB__->($m * $q, $q, $k - 1, $j++);
        }
    }->(1, 2, $k);

    return $count;
}

# Run some tests

foreach my $k (1 .. 10) {

    my $upto = pn_primorial($k) + int(rand(1e5));

    my $x = k_prime_count($upto, $k);
    my $y = almost_prime_count($k, $upto);

    say "Testing: $k with n = $upto -> $x";

    $x == $y
      or die "Error: $x != $y";
}

say '';

foreach my $k (1 .. 10) {
    printf("Count of %2d-almost primes <= 10^n: %s\n", $k, join(', ', map { k_prime_count(powint(10, $_), $k) } 0 .. 10));
}

__END__
Count of  1-almost primes <= 10^n: 0, 4, 25, 168, 1229, 9592, 78498, 664579, 5761455, 50847534, 455052511
Count of  2-almost primes <= 10^n: 0, 4, 34, 299, 2625, 23378, 210035, 1904324, 17427258, 160788536, 1493776443
Count of  3-almost primes <= 10^n: 0, 1, 22, 247, 2569, 25556, 250853, 2444359, 23727305, 229924367, 2227121996
Count of  4-almost primes <= 10^n: 0, 0, 12, 149, 1712, 18744, 198062, 2050696, 20959322, 212385942, 2139236881
Count of  5-almost primes <= 10^n: 0, 0, 4, 76, 963, 11185, 124465, 1349779, 14371023, 150982388, 1570678136
Count of  6-almost primes <= 10^n: 0, 0, 2, 37, 485, 5933, 68963, 774078, 8493366, 91683887, 977694273
Count of  7-almost primes <= 10^n: 0, 0, 0, 14, 231, 2973, 35585, 409849, 4600247, 50678212, 550454756
Count of  8-almost primes <= 10^n: 0, 0, 0, 7, 105, 1418, 17572, 207207, 2367507, 26483012, 291646797
Count of  9-almost primes <= 10^n: 0, 0, 0, 2, 47, 671, 8491, 101787, 1180751, 13377156, 148930536
Count of 10-almost primes <= 10^n: 0, 0, 0, 0, 22, 306, 4016, 49163, 578154, 6618221, 74342563
