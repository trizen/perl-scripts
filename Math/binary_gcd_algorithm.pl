#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 12 August 2017
# https://github.com/trizen

# Algorithm invented by J. Stein in 1967, described in the
# book "Algorithmic Number Theory" by Eric Bach and Jeffrey Shallit.

use 5.010;
use strict;
use warnings;

sub binary_gcd {
    my ($u, $v) = @_;

    my $g = 1;

    while (($u & 1) == 0 and ($v & 1) == 0) {
        $u >>= 1;
        $v >>= 1;
        $g <<= 1;
    }

    while ($u != 0) {
        if (($u & 1) == 0) {
            $u >>= 1;
        }
        elsif (($v & 1) == 0) {
            $v >>= 1;
        }
        elsif ($u >= $v) {
            $u -= $v;
            $u >>= 1;
        }
        else {
            $v -= $u;
            $v >>= 1;
        }
    }

    return ($g * $v);
}

say binary_gcd(10628640, 3628800);     #=> 1440
say binary_gcd(3628800,  10628640);    #=> 1440
