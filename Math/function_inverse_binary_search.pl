#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 10 July 2019
# https://github.com/trizen

# Compute the inverse of any function, using the binary search algorithm.

# See also:
#   https://en.wikipedia.org/wiki/Binary_search_algorithm

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(:overload approx_cmp float);

sub binary_inverse ($n, $f, $min = 0, $max = $n, $prec = 192) {

    local $Math::AnyNum::PREC = "$prec";

    ($min, $max) = ($max, $min) if ($min > $max);

    $min = float($min);
    $max = float($max);

    for (; ;) {
        my $m = ($min + $max) / 2;
        my $c = approx_cmp($f->($m), $n);

        if ($c < 0) {
            $min = $m;
        }
        elsif ($c > 0) {
            $max = $m;
        }
        else {
            return $m;
        }
    }
}

say binary_inverse(2,   sub ($x) { exp($x) });    # solution to x for: exp(x) =   2
say binary_inverse(43,  sub ($x) { $x**2 });      # solution to x for:    x^2 =  43
say binary_inverse(-43, sub ($x) { $x**3 });      # solution to x for:    x^3 = -43

# Find the value of x such that Li(x) = 100
say binary_inverse(100, sub ($x) { Math::AnyNum::Li($x) }, 1, 1e6);    #=> 488.871909852807531906050863920333348273780185564
