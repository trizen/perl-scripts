#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 01 October 2016
# Website: https://github.com/trizen

# Approximate nth-roots using Newton's method.

use 5.010;
use strict;
use warnings;

use Math::BigNum qw(:constant);

sub nth_root {
    my ($n, $x) = @_;

    my $eps = 10**-($Math::BigNum::PREC / 4);

    my $m = $n;
    my $r = 0;

    while (abs($m - $r) > $eps) {
        $r = $m;
        $m = ((($n - 1)->fmul($r) + $x->fdiv($r->fpow($n - 1)))->fdiv($n));
    }

    $r;
}

say nth_root(2,  2);
say nth_root(3,  125);
say nth_root(7,  42**7);
say nth_root(42, 987**42);
