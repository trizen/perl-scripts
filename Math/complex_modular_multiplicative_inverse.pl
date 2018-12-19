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

use Math::GComplex qw(cplx floor);
use experimental qw(signatures lexical_subs);

sub complex_gcd ($a, $b) {

    my ($x, $y) = ($a, $b);

    while ($b != 0) {

        ($a, $b) = ($b, $a % $b);
        ($x, $y) = ($y, $x % $y) if $y != 0;
        ($x, $y) = ($y, $x % $y) if $y != 0;

        if ($y != 0 and $a == $x and $y == $b) {
            return undef;    # cycle detected
        }
    }

    return abs($a);
}

sub complex_modular_inverse ($a, $n) {

    my $g = complex_gcd($a, $n);

    (defined($g) and $g == 1) or return undef;

    my sub inverse ($a, $n, $i) {

        my ($u, $w) = ($i, 0);
        my ($q, $r) = (0, 0);

        my $c = $n;

        while ($c != 0) {
            ($q, $r) = (floor($a / $c), $a % $c);
            ($a, $c) = ($c, $r);
            ($u, $w) = ($w, $u - $q * $w);
        }

        return $u;
    }

    (grep { ($_ * $a) % $n == 1 } map { inverse($a, $n, $_) } (1, -1, cplx(0, 1), cplx(0, -1)))[0];
}

say complex_modular_inverse(42, 2017);                 #=> (-48 0)
say complex_modular_inverse(cplx(3,  4),  2017);       #=> (1291 968)
say complex_modular_inverse(cplx(91, 23), 2017);       #=> (590 405)
say complex_modular_inverse(cplx(43, 99), 1234567);    #=> (-215016 -567265)

# Non-existent inverses
say complex_modular_inverse(cplx(43, 99), 2017) // 'undefined';    #=> undefined
say complex_modular_inverse(cplx(43, 99), 1234) // 'undefined';    #=> undefined
