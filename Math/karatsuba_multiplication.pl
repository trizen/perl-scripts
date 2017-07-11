#!/usr/bin/perl

# A simple implementation of the Karatsuba multiplication,
# which was the first subquadratic-time algorithm ever invented.

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use Math::AnyNum qw(:overload);
use Math::AnyNum qw(ceil divmod ipow2);

sub karatsuba_multiplication ($x, $y, $n = 8) {

    if ($n <= 1) {
        return $x * $y;
    }

    my $m = ceil($n / 2);

    my ($a, $b) = divmod($x, ipow2($m));
    my ($c, $d) = divmod($y, ipow2($m));

    my $e = karatsuba_multiplication($a,      $c,      $m);
    my $f = karatsuba_multiplication($b,      $d,      $m);
    my $g = karatsuba_multiplication($a - $b, $c - $d, $m);

    (ipow2(2 * $m) * $e) + (ipow2($m) * ($e + $f - $g)) + $f;
}

say karatsuba_multiplication(122, 422);    # 122 * 422 = 51484
