#!/usr/bin/perl

# A simple implementation of the Karatsuba multiplication.

# See also:
#   https://en.wikipedia.org/wiki/Karatsuba_algorithm

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use Math::AnyNum qw(:overload);
use Math::AnyNum qw(divmod);

sub karatsuba_multiplication ($x, $y, $n = 8) {

    if ($n <= 1) {
        return $x * $y;
    }

    my $m = ($n % 2 == 0) ? ($n >> 1) : (($n >> 1) + 1);

    my ($a, $b) = divmod($x, 1 << $m);
    my ($c, $d) = divmod($y, 1 << $m);

    my $e = __SUB__->($a,      $c,      $m);
    my $f = __SUB__->($b,      $d,      $m);
    my $g = __SUB__->($a - $b, $c - $d, $m);

    ($e << (2*$m)) + (($e + $f - $g) << $m) + $f;
}

say karatsuba_multiplication(122, 422);    # 122 * 422 = 51484
