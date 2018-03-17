#!/usr/bin/perl

# Algorithm for computing the modular inverse: 1/k mod n, with gcd(k, n) = 1.

# Algorithm presented in the book:
#
#   Modern Computer Arithmetic
#           - by Richard P. Brent and Paul Zimmermann
#

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

sub divmod ($n, $k) {
    (int($n / $k), $n % $k);
}

sub modular_inverse ($k, $n) {

    my ($u, $w) = (1, 0);
    my ($q, $r) = (0, 0);

    my $c = $n;

    while ($c != 0) {
        ($q, $r) = divmod($k, $c);
        ($k, $c) = ($c, $r);
        ($u, $w) = ($w, $u - $q*$w);
    }

    $u += $n if ($u < 0);

    return $u;
}

say modular_inverse(42, 2017);      #=> 1969
