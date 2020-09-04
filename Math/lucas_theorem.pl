#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date 04 September 2020
# https://github.com/trizen

# Simple implementation of Lucas's theorem, for computing binomial(n,k) mod p, for some prime p.

# See also:
#   https://en.wikipedia.org/wiki/Lucas%27s_theorem

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(:all);

sub lucas_theorem ($n, $k, $p) {

    if ($n < $k) {
        return 0;
    }

    my $res = 1;

    while ($k > 0) {
        my ($Nr, $Kr) = ($n % $p, $k % $p);

        if ($Nr < $Kr) {
            return 0;
        }

        ($n, $k) = (divint($n, $p), divint($k, $p));
        $res = mulmod($res, binomial($Nr, $Kr), $p);
    }

    return $res;
}

sub lucas_theorem_alt ($n, $k, $p) {        # alternative implementation

    if ($n < $k) {
        return 0;
    }

    my @Nd = reverse todigits($n, $p);
    my @Kd = reverse todigits($k, $p);

    my $res = 1;

    foreach my $i (0 .. $#Kd) {

        my $Nr = $Nd[$i];
        my $Kr = $Kd[$i];

        if ($Nr < $Kr) {
            return 0;
        }

        $res = mulmod($res, binomial($Nr, $Kr), $p);
    }

    return $res;
}

say lucas_theorem(1e10,           1e5,           1009);    #=> 559
say lucas_theorem(powint(10, 18), powint(10, 9), 2957);    #=> 2049

say '';

say lucas_theorem_alt(1e10,           1e5,           1009);    #=> 559
say lucas_theorem_alt(powint(10, 18), powint(10, 9), 2957);    #=> 2049
