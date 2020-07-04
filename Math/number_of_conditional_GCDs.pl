#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 04 July 2018
# https://github.com/trizen

# Find the number of k = 1..n for which GCD(n,k) satisfies a certain condition (e.g.:
# GCD(n,k) is a prime number), using the divisors of `n` and the Euler totient function.

# See also:
#   https://oeis.org/A117494 -- Number of k = 1..n for which GCD(n, k) is a prime
#   https://oeis.org/A116512 -- Number of k = 1..n for which GCD(n, k) is a power of a prime
#   https://oeis.org/A206369 -- Number of k = 1..n for which GCD(n, k) is a square
#   https://oeis.org/A078429 -- Number of k = 1..n for which GCD(n, k) is a cube
#   https://oeis.org/A063658 -- Number of k = 1..n for which GCD(n, k) is divisible by a square greater than 1

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(divisors euler_phi is_prime is_square is_prime_power factorial);

sub conditional_euler_totient ($n, $condition) {

    my $count = 0;

    foreach my $d (divisors($n)) {
        if ($condition->($d)) {
            $count += euler_phi($n / $d);
        }
    }

    return $count;
}

say "Number of values of k with 1 <= k <= n such that gcd(n, k) is a prime number";
say conditional_euler_totient(factorial(10), sub ($d) { is_prime($d) });    # 995328
say conditional_euler_totient(factorial(11), sub ($d) { is_prime($d) });    # 10782720
say conditional_euler_totient(factorial(12), sub ($d) { is_prime($d) });    # 129392640

say '';

say "Number of values of k with 1 <= k <= n such that gcd(n, k) is a square";
say conditional_euler_totient(factorial(10), sub ($d) { is_square($d) });    # 1314306
say conditional_euler_totient(factorial(11), sub ($d) { is_square($d) });    # 13143060
say conditional_euler_totient(factorial(12), sub ($d) { is_square($d) });    # 156625560

say '';

say "Number of values of k with 1 <= k <= n such that gcd(n, k) is a prime power";
say conditional_euler_totient(factorial(10), sub ($d) { is_prime_power($d) });    # 1589760
say conditional_euler_totient(factorial(11), sub ($d) { is_prime_power($d) });    # 16727040
say conditional_euler_totient(factorial(12), sub ($d) { is_prime_power($d) });    # 200724480
