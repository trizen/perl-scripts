#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 16 January 2019
# https://github.com/trizen

# Efficient formula due to Jeffrey C. Lagarias and Harsh Meht for computing the prime-power factorization of the product of binomials.

# Using the identities:
#   G(n) = Product_{k=0..n} binomial(n, k) = Product_{k=1..n} k^(2*k - n - 1)
#                                          = hyperfactorial(n)/superfactorial(n)

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

no warnings 'recursion';

use experimental qw(signatures);
use ntheory qw(forprimes todigits vecsum);

my @cache;

sub sum_of_digits ($n, $p) {
    return 0 if ($n <= 0);
    $cache[$n][$p] //= vecsum(todigits($n - 1, $p)) + sum_of_digits($n - 1, $p);
}

sub power_of_product_of_binomials ($n, $p) {
    (2 * sum_of_digits($n, $p) - ($n - 1) * vecsum(todigits($n, $p))) / ($p - 1);
}

sub prime_factorization_of_binomial_product ($n) {
    my @pp;

    forprimes {

        my $p = $_;
        my $k = power_of_product_of_binomials($n, $p);

        push @pp, [$p, $k];
    } $n;

    return @pp;
}

foreach my $n (2 .. 20) {
    my @pp = prime_factorization_of_binomial_product($n);
    printf("G(%2d) = %s\n", $n, join(' * ', map { sprintf("%2d^%-2d", $_->[0], $_->[1]) } @pp));
}

__END__
G( 2) =  2^1
G( 3) =  2^0  *  3^2
G( 4) =  2^5  *  3^1
G( 5) =  2^2  *  3^0  *  5^4
G( 6) =  2^4  *  3^4  *  5^3
G( 7) =  2^0  *  3^2  *  5^2  *  7^6
G( 8) =  2^17 *  3^0  *  5^1  *  7^5
G( 9) =  2^10 *  3^14 *  5^0  *  7^4
G(10) =  2^12 *  3^10 *  5^8  *  7^3
G(11) =  2^4  *  3^6  *  5^6  *  7^2  * 11^10
G(12) =  2^18 *  3^13 *  5^4  *  7^1  * 11^9
G(13) =  2^8  *  3^8  *  5^2  *  7^0  * 11^8  * 13^12
G(14) =  2^11 *  3^3  *  5^0  *  7^12 * 11^7  * 13^11
G(15) =  2^0  *  3^12 *  5^12 *  7^10 * 11^6  * 13^10
G(16) =  2^49 *  3^6  *  5^9  *  7^8  * 11^5  * 13^9
G(17) =  2^34 *  3^0  *  5^6  *  7^6  * 11^4  * 13^8  * 17^16
G(18) =  2^36 *  3^28 *  5^3  *  7^4  * 11^3  * 13^7  * 17^15
G(19) =  2^20 *  3^20 *  5^0  *  7^2  * 11^2  * 13^6  * 17^14 * 19^18
G(20) =  2^42 *  3^12 *  5^16 *  7^0  * 11^1  * 13^5  * 17^13 * 19^17
