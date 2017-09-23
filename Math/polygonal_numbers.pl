#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 24 September 2017
# License: GPLv3
# https://github.com/trizen

# Util functions for working with polygonal numbers.

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(:overload);

sub polygonal_number ($n, $k) {
    $n * ($k * ($n - 1) - 2 * ($n - 2)) / 2;
}

sub polygonal_root ($n, $k) {
    (sqrt(8 * ($k - 2) * $n + ($k - 4)**2) + $k - 4) / (2 * ($k - 2));
}

sub is_polygonal ($n, $k) {
    polygonal_root($n, $k)->is_int;
}

#<<<
say "Triangular numbers: ", join(', ', grep { is_polygonal($_, 3) } 1 .. 100);
say "Square numbers:     ", join(', ', grep { is_polygonal($_, 4) } 1 .. 100);
say "Pentagonal numbers: ", join(', ', grep { is_polygonal($_, 5) } 1 .. 100);
say "Hexagonal numbers:  ", join(', ', grep { is_polygonal($_, 6) } 1 .. 100);
say "Heptagonal numbers: ", join(', ', grep { is_polygonal($_, 7) } 1 .. 100);
say "Octagonal numbers:  ", join(', ', grep { is_polygonal($_, 8) } 1 .. 100);
#>>>

say '';

#<<<
say "Decagonal numbers: ", join(', ', map { polygonal_number($_, 10) } 1..10);
say "25-gonal numbers:  ", join(', ', map { polygonal_number($_, 25) } 1..10);
say "50-gonal numbers:  ", join(', ', map { polygonal_number($_, 50) } 1..10);
#>>>

__END__
Triangular numbers: 1, 3, 6, 10, 15, 21, 28, 36, 45, 55, 66, 78, 91
Square numbers:     1, 4, 9, 16, 25, 36, 49, 64, 81, 100
Pentagonal numbers: 1, 5, 12, 22, 35, 51, 70, 92
Hexagonal numbers:  1, 6, 15, 28, 45, 66, 91
Heptagonal numbers: 1, 7, 18, 34, 55, 81
Octagonal numbers:  1, 8, 21, 40, 65, 96

Decagonal numbers: 1, 10, 27, 52, 85, 126, 175, 232, 297, 370
25-gonal numbers:  1, 25, 72, 142, 235, 351, 490, 652, 837, 1045
50-gonal numbers:  1, 50, 147, 292, 485, 726, 1015, 1352, 1737, 2170
