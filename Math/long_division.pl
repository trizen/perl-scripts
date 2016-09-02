#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 24 December 2012
# https://github.com/trizen

# Long division with arbitrary precision.

use 5.016;
use strict;
use warnings;

sub divide ($$$) {
    my ($x, $y, $f, $z) = @_;

    my $c = 0;
    sub {
        my $i = int($x / $y);

        $z .= $i;
        $x -= $y * $i;

        my $s = -1;
        until ($x >= $y) { $x *= 10; ++$s; $x || last }

        $z .= '.' if !$c;
        $z .= '0' x $s;
        $c += $s + 1;

        __SUB__->() if $c <= $f;
      }
      ->();

    return $z;
}

say divide(634,  212,   64);
say divide(9,    379,   64);
say divide(42.5, 232.7, 64);

say divide(7246,8743,64);
