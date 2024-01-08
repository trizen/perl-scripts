#!/usr/bin/perl

# Formula for computing the sum of divisors of the product of binomials.

# Using the identities:
#   Product_{k=0..n} binomial(n, k) = Product_{k=1..n} k^(2*k - n - 1)
#                                   = hyperfactorial(n)/superfactorial(n)

# and the fact that the sigma function is multiplicative with:
#   sigma_m(p^k) = (p^(m*(k+1)) - 1)/(p^m - 1)

# See also:
#   https://oeis.org/A001142
#   https://oeis.org/A323444

# Paper:
#   Jeffrey C. Lagarias, Harsh Mehta
#   Products of binomial coefficients and unreduced Farey fractions
#   https://arxiv.org/abs/1409.4145

use 5.020;
use strict;
use warnings;

use Math::AnyNum qw(prod ipow);
use experimental qw(signatures);
use ntheory qw(primes todigits vecsum);

my @cache;

sub sum_of_digits ($n, $p) {
    return 0 if ($n <= 0);
    $cache[$n][$p] //= vecsum(todigits($n - 1, $p)) + sum_of_digits($n - 1, $p);
}

sub power_of_product_of_binomials ($n, $p) {
    (2 * sum_of_digits($n, $p) - ($n - 1) * vecsum(todigits($n, $p))) / ($p - 1);
}

sub sigma_of_binomial_product ($n, $m = 1) {
    prod(
        map {
            my $p = $_;
            my $k = power_of_product_of_binomials($n, $p);
            (ipow($p, $m * ($k + 1)) - 1) / (ipow($p, $m) - 1);
        } @{primes($n)}
    );
}

say sigma_of_binomial_product(10);    #=> 141699428035793200
say sigma_of_binomial_product(10, 2); #=> 1675051201226374788235139281367100
