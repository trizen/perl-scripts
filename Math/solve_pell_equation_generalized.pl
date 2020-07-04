#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 29 May 2018
# https://github.com/trizen

# Find the smallest solution in positive integers to the generalized Pell equation:
#
#       x^2 - d*y^2 = n
#
# where `d` and `n` are given.

# See also:
#   https://en.wikipedia.org/wiki/Pell%27s_equation

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(idiv isqrt is_square irand);

sub solve_pell ($n, $u = 1) {

    return () if is_square($n);

    my $x = isqrt($n);
    my $y = $x;
    my $z = 1;
    my $r = $x + $x;

    my ($f1, $f2) = (1, $x);

    for (1 .. 4 * $x * log($x) + 10) {

        $y = $r * $z - $y;
        $z = idiv($n - $y * $y, $z) || return;
        $r = idiv($x + $y, $z);

        ($f1, $f2) = ($f2, $r * $f2 + $f1);

        my $p = ($n * ($f1 * $f1 - $u)) << 2;

        if (is_square($p)) {
            my $t = isqrt($p) >> 1;
            $t % $n == 0 || next;
            return ($f1, idiv($t, $n));
        }
    }

    return ();
}

foreach my $d (1 .. 99) {
    my ($x, $y) = solve_pell($d, irand(1, 9) * (irand(0, 1) ? 1 : -1));

    if (defined($x)) {
        printf("x^2 - %2dy^2 = %2d    minimum solution: x=%15s and y=%15s\n", $d, $x**2 - $d * $y**2, $x, $y);
    }

}

__END__
x^2 -  2y^2 =  9    minimum solution: x=              3 and y=              0
x^2 -  5y^2 =  4    minimum solution: x=              2 and y=              0
x^2 - 14y^2 = -5    minimum solution: x=              3 and y=              1
x^2 - 15y^2 =  9    minimum solution: x=              3 and y=              0
x^2 - 21y^2 = -3    minimum solution: x=              9 and y=              2
x^2 - 28y^2 =  1    minimum solution: x=            127 and y=             24
x^2 - 29y^2 = -4    minimum solution: x=              5 and y=              1
x^2 - 31y^2 = -6    minimum solution: x=              5 and y=              1
x^2 - 47y^2 =  2    minimum solution: x=              7 and y=              1
x^2 - 53y^2 = -4    minimum solution: x=              7 and y=              1
x^2 - 58y^2 = -6    minimum solution: x=             38 and y=              5
x^2 - 61y^2 =  1    minimum solution: x=     1766319049 and y=      226153980
x^2 - 67y^2 =  9    minimum solution: x=            131 and y=             16
x^2 - 68y^2 =  1    minimum solution: x=             33 and y=              4
x^2 - 69y^2 = -5    minimum solution: x=              8 and y=              1
x^2 - 71y^2 =  1    minimum solution: x=           3480 and y=            413
x^2 - 89y^2 = -8    minimum solution: x=              9 and y=              1
x^2 - 92y^2 =  4    minimum solution: x=             48 and y=              5
x^2 - 93y^2 =  4    minimum solution: x=             29 and y=              3
x^2 - 95y^2 =  1    minimum solution: x=             39 and y=              4
x^2 - 97y^2 =  1    minimum solution: x=       62809633 and y=        6377352
x^2 - 98y^2 =  1    minimum solution: x=             99 and y=             10
