#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 19 December 2018
# https://github.com/trizen

# Algorithm for computing the modular multiplicative inverse of complex numbers:
#   1/a mod n, with |gcd(a, n)| = 1.

# Solution to `x` for:
#   a*x = 1 (mod n)

use 5.020;
use strict;
use warnings;

use Math::AnyNum qw(:overload conj round);
use experimental qw(signatures lexical_subs);

sub complex_gcd ($a, $b) {

    my ($x, $y) = ($a, $b);

    while ($b != 0) {
        my $q = round($a / $b);
        my $r = $a - $b * $q;

        ($a, $b) = ($b, $r);
    }

    return $a;
}

sub complex_modular_inverse ($a, $n) {

    my $g = complex_gcd($a, $n);

    abs($g) == 1 or return undef;

    my sub inverse ($a, $n, $i) {

        my ($u, $w) = ($i, 0);
        my ($q, $r) = (0, 0);

        my $c = $n;

        while ($c != 0) {

            $q = round($a / $c);
            $r = $a - $c * $q;

            ($a, $c) = ($c, $r);
            ($u, $w) = ($w, $u - $q * $w);
        }

        return $u % $n;
    }

    (grep { ($_ * $a) % $n == 1 } map { inverse($a, $n, $_) } (conj($g), 1, -1, i, -i))[0];
}

say complex_modular_inverse(42,          2017);       #=> 1969
say complex_modular_inverse(3 + 4 * i,   2017);       #=> 1291+968i
say complex_modular_inverse(91 + 23 * i, 2017);       #=> 590+405i
say complex_modular_inverse(43 + 99 * i, 2017);       #=> 1709+1272i
say complex_modular_inverse(43 + 99 * i, 1234567);    #=> 1019551+667302i

# Non-existent inverses
say complex_modular_inverse(43 + 99 * i, 1234) // 'undefined';    #=> undefined
