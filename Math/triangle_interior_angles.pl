#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 22 January 2018
# https://github.com/trizen

# Formula for finding the interior angles of a triangle, given its side lengths.

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(acos rad2deg);

my $x = 3;
my $y = 4;
my $z = 5;

say rad2deg(acos(($y**2 + $z**2 - $x**2) / (2 * $y * $z)));     # 36.869...
say rad2deg(acos(($x**2 - $y**2 + $z**2) / (2 * $x * $z)));     # 53.130...
say rad2deg(acos(($x**2 + $y**2 - $z**2) / (2 * $x * $y)));     # 90
