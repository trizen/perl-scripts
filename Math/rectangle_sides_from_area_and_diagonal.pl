#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 22 January 2018
# https://github.com/trizen

# Formula for finding the length of the sides of a rectangle
# when only its area and the length of its diagonal are known.

# See also:
#   https://en.wikipedia.org/wiki/Fermat%27s_factorization_method

use 5.010;
use strict;
use warnings;

sub extract_rectangle_sides {
    my ($n, $h) = @_;

    my $s = (2 * $n + $h);

    my $x = sqrt($s - 4 * $n) / 2;
    my $y = sqrt($s) / 2;

    return ($y - $x, $x + $y);
}

my $p = 43;
my $q = 97;

my $n = $p * $q;          # rectangle area
my $h = $p**2 + $q**2;    # diagonal length, squared

say join(' ', extract_rectangle_sides($n, $h));
