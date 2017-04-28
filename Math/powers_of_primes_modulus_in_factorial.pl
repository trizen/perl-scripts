#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 15 September 2016
# Website: https://github.com/trizen

# Count the number of factors of p modulus p^k in (p^n)! with k <= n.

# Example:
#           p   n  k
#   fpower(43, 10, 7) = 6471871693
#
# because (43^10)! contains 514559102697244 factors of 43
# and 514559102697244 mod 43^7 = 6471871693

# See also:
#   https://projecteuler.net/problem=288

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(:overload powmod);

#
## Iterative version
#
sub fpower {
    my ($p, $n, $k) = @_;

    return 0 if $n <= 0;
    $k = $n if $k > $n;

    my $sum = 0;
    my $mod = $p**$k;

    while ($n > 0) {
        $sum += powmod($p, --$n, $mod);
    }

    $sum;
}

#
## Recursive version
#
sub _fpower_rec {
    my ($p, $n, $mod) = @_;
    $n == 0 ? 0 : powmod($p, $n - 1, $mod) + _fpower_rec($p, $n - 1, $mod);
}

sub fpower_rec {
    my ($p, $n, $k) = @_;

    return 0 if $n <= 0;
    $k = $n if $k > $n;

    _fpower_rec($p, $n, $p**$k);
}

say fpower(43, 10, 7);
say fpower_rec(43, 10, 7);
