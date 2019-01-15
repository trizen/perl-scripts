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
#   http://arxiv.org/abs/1409.4145

use 5.020;
use strict;
use warnings;

use ntheory qw(primes);
use Math::AnyNum qw(prod ipow);
use experimental qw(signatures);

sub superfactorial_power ($n, $p) {

    my $r = 0;

    foreach my $k (1 .. $n) {
        while ($k > 0) {
            $k = int($k / $p);
            $r += $k;
        }
    }

    return $r;
}

sub hyperfactorial_power ($n, $p) {

    my $r = 0;
    my $k = $n;

    while ($k > 0) {
        $k = int($k / $p);
        $r += $k;
    }

    my $t = superfactorial_power($n - 1, $p);
    $n * $r - $t;
}

sub sigma_of_binomial_product ($n, $m = 1) {
    prod(
        map {
            my $p = $_;
            my $k = hyperfactorial_power($n, $p) - superfactorial_power($n, $p);
            (ipow($p, $m * ($k + 1)) - 1) / (ipow($p, $m) - 1);
        } @{primes($n)}
    );
}

say sigma_of_binomial_product(10);    #=> 141699428035793200
say sigma_of_binomial_product(10, 2); #=> 1675051201226374788235139281367100
