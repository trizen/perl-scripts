#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 16 January 2019
# https://github.com/trizen

# Efficient formula due to Jeffrey C. Lagarias and Harsh Meht for computing the prime-power factorization of the superfactorial(n) and hyperfactorial(n).

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
use ntheory qw(todigits vecsum forprimes);
use Math::AnyNum qw(superfactorial hyperfactorial prod ipow);

sub factorial_power ($n, $p) {
    ($n - vecsum(todigits($n, $p))) / ($p - 1);
}

my @cache;

sub superfactorial_power ($n, $p) {
    return 0 if ($n <= 0);
    $cache[$n][$p] //= superfactorial_power($n - 1, $p) + factorial_power($n, $p);
}

sub hyperfactorial_power ($n, $p) {
    $n * factorial_power($n, $p) - superfactorial_power($n - 1, $p);
}

sub prime_factorization_of_superfactorial ($n) {
    my @pp;

    forprimes {

        my $p = $_;
        my $k = superfactorial_power($n, $p);

        push @pp, [$p, $k];
    }
    $n;

    return @pp;
}

sub prime_factorization_of_hyperfactorial ($n) {
    my @pp;

    forprimes {

        my $p = $_;
        my $k = hyperfactorial_power($n, $p);

        push @pp, [$p, $k];
    }
    $n;

    return @pp;
}

foreach my $n (2 .. 15) {

    my @S_pp = prime_factorization_of_superfactorial($n);
    my @H_pp = prime_factorization_of_hyperfactorial($n);

    printf("S(%2d) = %s\n", $n, join(' * ', map { sprintf("%2d^%-2d", $_->[0], $_->[1]) } @S_pp));
    printf("H(%2d) = %s\n", $n, join(' * ', map { sprintf("%2d^%-2d", $_->[0], $_->[1]) } @H_pp));

    prod(map { ipow($_->[0], $_->[1]) } @S_pp) == superfactorial($n) or die "S($n) error";
    prod(map { ipow($_->[0], $_->[1]) } @H_pp) == hyperfactorial($n) or die "H($n) error";
}

__END__
S( 2) =  2^1
H( 2) =  2^2
S( 3) =  2^2  *  3^1
H( 3) =  2^2  *  3^3
S( 4) =  2^5  *  3^2
H( 4) =  2^10 *  3^3
S( 5) =  2^8  *  3^3  *  5^1
H( 5) =  2^10 *  3^3  *  5^5
S( 6) =  2^12 *  3^5  *  5^2
H( 6) =  2^16 *  3^9  *  5^5
S( 7) =  2^16 *  3^7  *  5^3  *  7^1
H( 7) =  2^16 *  3^9  *  5^5  *  7^7
S( 8) =  2^23 *  3^9  *  5^4  *  7^2
H( 8) =  2^40 *  3^9  *  5^5  *  7^7
S( 9) =  2^30 *  3^13 *  5^5  *  7^3
H( 9) =  2^40 *  3^27 *  5^5  *  7^7
S(10) =  2^38 *  3^17 *  5^7  *  7^4
H(10) =  2^50 *  3^27 *  5^15 *  7^7
S(11) =  2^46 *  3^21 *  5^9  *  7^5  * 11^1
H(11) =  2^50 *  3^27 *  5^15 *  7^7  * 11^11
S(12) =  2^56 *  3^26 *  5^11 *  7^6  * 11^2
H(12) =  2^74 *  3^39 *  5^15 *  7^7  * 11^11
S(13) =  2^66 *  3^31 *  5^13 *  7^7  * 11^3  * 13^1
H(13) =  2^74 *  3^39 *  5^15 *  7^7  * 11^11 * 13^13
S(14) =  2^77 *  3^36 *  5^15 *  7^9  * 11^4  * 13^2
H(14) =  2^88 *  3^39 *  5^15 *  7^21 * 11^11 * 13^13
S(15) =  2^88 *  3^42 *  5^18 *  7^11 * 11^5  * 13^3
H(15) =  2^88 *  3^54 *  5^30 *  7^21 * 11^11 * 13^13
