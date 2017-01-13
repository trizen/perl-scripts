#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 10 January 2017
# https://github.com/trizen

# An example for finding the smallest value `x` in:
#
#   x^e = r (mod n)

use 5.010;
use strict;
use warnings;

use ntheory qw(invmod powmod euler_phi);

sub discrete_root {
    my ($e, $r, $n) = @_;
    my $d = invmod($e, euler_phi($n));
    powmod($r, $d, $n);
}

#
## Solves for x in x^65537 = 1653 (mod 2279)
#

say discrete_root(65537, 1653, 2279);        # 1234
