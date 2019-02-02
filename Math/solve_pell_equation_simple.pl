#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 02 February 2019
# https://github.com/trizen

# Find the smallest solution in positive integers to Pell's equation: x^2 - d*y^2 = 1, where `d` is known.

# See also:
#   https://rosettacode.org/wiki/Pell%27s_equation
#   https://en.wikipedia.org/wiki/Pell%27s_equation

use 5.020;
use strict;
use warnings;

use Math::AnyNum qw(is_square isqrt idiv);
use experimental qw(signatures);

sub solve_pell ($n, $w = 1) {

    return () if is_square($n);

    my $x = isqrt($n);
    my $y = $x;
    my $z = 1;
    my $r = 2 * $x;

    my ($e1, $e2) = (1, 0);
    my ($f1, $f2) = (0, 1);

    for (1 .. $n) {

        $y = $r * $z - $y;
        $z = ($n - $y * $y) / $z;
        $r = idiv(($x + $y), $z);

        my $A = $e2 + $x * $f2;
        my $B = $f2;

        if ($z == abs($w) and $A**2 - $n * $B**2 == $w) {
            return ($A, $B);
        }

        ($e1, $e2) = ($e2, $r * $e2 + $e1);
        ($f1, $f2) = ($f2, $r * $f2 + $f1);
    }

    return ();
}

foreach my $d(-3, -1, 1, 9) {
    foreach my $n (61, 109, 181, 277) {
        my ($x, $y) = solve_pell($n, $d);
        printf("x^2 - %3d*y^2 = %2s for x = %-21s and y = %s\n", $n, $x**2 - $n * $y**2, $x, $y);
    }
}

__END__
x^2 -  61*y^2 = -3 for x = 5639                  and y = 722
x^2 - 109*y^2 = -3 for x = 1399                  and y = 134
x^2 - 181*y^2 = -3 for x = 11262809              and y = 837158
x^2 - 277*y^2 = -3 for x = 233                   and y = 14
x^2 -  61*y^2 = -1 for x = 29718                 and y = 3805
x^2 - 109*y^2 = -1 for x = 8890182               and y = 851525
x^2 - 181*y^2 = -1 for x = 1111225770            and y = 82596761
x^2 - 277*y^2 = -1 for x = 8920484118            and y = 535979945
x^2 -  61*y^2 =  1 for x = 1766319049            and y = 226153980
x^2 - 109*y^2 =  1 for x = 158070671986249       and y = 15140424455100
x^2 - 181*y^2 =  1 for x = 2469645423824185801   and y = 183567298683461940
x^2 - 277*y^2 =  1 for x = 159150073798980475849 and y = 9562401173878027020
x^2 -  61*y^2 =  9 for x = 125                   and y = 16
x^2 - 109*y^2 =  9 for x = 3914405               and y = 374932
x^2 - 181*y^2 =  9 for x = 43805                 and y = 3256
x^2 - 277*y^2 =  9 for x = 108581                and y = 6524
