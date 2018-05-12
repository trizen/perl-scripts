#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 12 May 2018
# https://github.com/trizen

# Two algorithms for computing the sum of the digits of an integer, in a given base.

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(idiv divmod irand sumdigits ipow2);

sub sumdigits_1 ($n, $k) {

    my $N = $n;
    my $S = 0;

    while ($n >= 1) {
        $n = idiv($n, $k);
        $S += $n;
    }

    return ($N - $S * ($k - 1));
}

sub sumdigits_2 ($n, $k) {

    my $m = 0;
    my $S = 0;

    while ($n >= 1) {
        ($n, $m) = divmod($n, $k);
        $S += $m;
    }

    return $S;
}

my $n = irand(2, ipow2(100000));
my $k = irand(2, 1000);

say sumdigits($n, $k);    # provided by Math::AnyNum
say sumdigits_1($n, $k);
say sumdigits_2($n, $k);
