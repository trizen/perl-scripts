#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 08 March 2023
# https://github.com/trizen

# Generate Lucas-Carmichael numbers from a given multiple.

# See also:
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

use 5.036;
use Math::GMPz;
use ntheory qw(:all);

sub lucas_carmichael_from_multiple ($m, $callback) {

    my $L = lcm(map { addint($_, 1) } factor($m));
    my $v = mulmod(invmod($m, $L) // (return), -1, $L);

    for (my $p = $v ; ; $p += $L) {

        gcd($m, $p) == 1 or next;

        my @factors = factor_exp($p);
        (vecall { $_->[1] == 1 } @factors) || next;

        my $n = $m * $p;
        my $l = lcm(map { addint($_->[0], 1) } @factors);

        if (($n + 1) % $l == 0) {
            $callback->($n);
        }
    }
}

lucas_carmichael_from_multiple(11 * 17, sub ($n) { say $n });
