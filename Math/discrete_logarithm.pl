#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 10 January 2016
# https://github.com/trizen

# An example for solving for `x` in:
#   x^e = r (mod n).

# See also:
#   https://en.wikipedia.org/wiki/Discrete_logarithm

use 5.010;
use strict;
use warnings;

use ntheory qw(invmod powmod factor);

sub discrete_log {
    my ($e, $n, $r) = @_;

    my ($p, $q) = factor($n);
    my $d = invmod($e, ($p-1)*($q-1));

    powmod($r, $d, $n);
}

#
## Solves: x^65537 = 1653 (mod 2279)
#
say discrete_log(65537, 2279, 1653);        # 1234
