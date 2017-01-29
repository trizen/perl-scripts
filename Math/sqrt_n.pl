#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 06 July 2013
# https://github.com/trizen

# Get the n^th root of a number.
# For example, sqrt_n(125, 3) == 5 because 5^3 == 125
#              sqrt_n(2694.64663369533, 7.19) == 3 because 3^7.19 == 2694.64663369533

#
## Solves x^y=z if you know 'y' and 'z'.
#
# x^3=125 --> sqrt_n(125, 3) --> 5
#
## A little bit more complicated than the straightforward: z^(1/y)
#

use 5.010;
use strict;
use warnings;

sub sqrt_n {
    my ($num, $pow) = @_;

    my $i   = int($pow) - 1;
    my $res = $num;

    for (1 .. $i) {
        $res = sqrt($res);
    }

    $res**(2**$i / $pow);
}

#
## Main
#

my $PI = atan2(0, -'inf');

say sqrt_n(125,              3);       # 5
say sqrt_n(2694.64663369533, 7.19);    # 3
say sqrt_n(13**$PI,          $PI);     # 13
say sqrt_n(25,               3);       # 2.92401773821287
