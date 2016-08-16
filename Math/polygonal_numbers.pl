#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 16 August 2016
# License: GPLv3
# Website: https://github.com/trizen

# Util functions for working with polygonal numbers.

# Inspired by: https://projecteuler.net/problem=61

use 5.010;
use strict;
use warnings;

sub quadratic_formula {
    my ($x, $y, $z) = @_;
    (-$y + sqrt($y**2 - 4 * $x * $z)) / (2 * $x);
}

#
## Generation
#

sub triangle {
    $_[0] * ($_[0] + 1) / 2;
}

sub square {
    $_[0] * $_[0];
}

sub pentagon {
    $_[0] * (3 * $_[0] - 1) / 2;
}

sub hexagon {
    $_[0] * (2 * $_[0] - 1);
}

sub heptagon {
    $_[0] * (5 * $_[0] - 3) / 2;
}

sub octagon {
    $_[0] * (3 * $_[0] - 2);
}

#
## Roots
#

sub triangle_root {
    quadratic_formula(1 / 2, 1 / 2, -$_[0]);
}

sub square_root {
    quadratic_formula(1, 0, -$_[0]);
}

sub pentagon_root {
    quadratic_formula(3 / 2, -1, -$_[0]);
}

sub hexagon_root {
    quadratic_formula(2, -1, -$_[0]);
}

sub heptagon_root {
    quadratic_formula(5 / 2, -3 / 2, -$_[0]);
}

sub octagon_root {
    quadratic_formula(3, -2, -$_[0]);
}

#
## Validation
#

sub is_triangle {
    triangle(int(triangle_root($_[0]))) == $_[0];
}

sub is_square {
    square(int(square_root($_[0]))) == $_[0];
}

sub is_pentagon {
    pentagon(int(pentagon_root($_[0]))) == $_[0];
}

sub is_hexagon {
    hexagon(int(hexagon_root($_[0]))) == $_[0];
}

sub is_heptagon {
    heptagon(int(heptagon_root($_[0]))) == $_[0];
}

sub is_octagon {
    octagon(int(octagon_root($_[0]))) == $_[0];
}

#<<<
say "Triangular numbers: ", join(', ', grep { is_triangle($_) } map { triangle($_) } 1 .. 10);
say "Square numbers:     ", join(', ', grep { is_square($_)   } map { square($_)   } 1 .. 10);
say "Pentagonal numbers: ", join(', ', grep { is_pentagon($_) } map { pentagon($_) } 1 .. 10);
say "Hexagonal numbers:  ", join(', ', grep { is_hexagon($_)  } map { hexagon($_)  } 1 .. 10);
say "Heptagonal numbers: ", join(', ', grep { is_heptagon($_) } map { heptagon($_) } 1 .. 10);
say "Octagonal numbers:  ", join(', ', grep { is_octagon($_)  } map { octagon($_)  } 1 .. 10);
#>>>

__END__
Triangular numbers: 1, 3, 6, 10, 15, 21, 28, 36, 45, 55
Square numbers:     1, 4, 9, 16, 25, 36, 49, 64, 81, 100
Pentagonal numbers: 1, 5, 12, 22, 35, 51, 70, 92, 117, 145
Hexagonal numbers:  1, 6, 15, 28, 45, 66, 91, 120, 153, 190
Heptagonal numbers: 1, 7, 18, 34, 55, 81, 112, 148, 189, 235
Octagonal numbers:  1, 8, 21, 40, 65, 96, 133, 176, 225, 280
