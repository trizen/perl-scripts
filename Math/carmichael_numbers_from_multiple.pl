#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 17 March 2023
# https://github.com/trizen

# Generate Carmichael numbers from a given multiple.

# See also:
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

use 5.036;
use Math::GMPz;
use ntheory qw(:all);

sub carmichael_from_multiple ($m, $callback) {

    my $L = lcm(map { subint($_, 1) } factor($m));
    my $v = invmod($m, $L) // return;

    for (my $p = $v ; ; $p += $L) {

        gcd($m, $p) == 1 or next;

        my @factors = factor_exp($p);
        (vecall { $_->[1] == 1 } @factors) || next;

        my $n = $m * $p;
        my $l = lcm(map { subint($_->[0], 1) } @factors);

        if (($n - 1) % $l == 0) {
            $callback->($n);
        }
    }
}

carmichael_from_multiple(13 * 19, sub ($n) { say $n });
