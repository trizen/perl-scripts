#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 31 August 2016
# License: GPLv3
# https://github.com/trizen

# Find a minimum solution to a Pell equation: x^2 - d*y^2 = 1, where `d` is known.

# See also:
#   https://en.wikipedia.org/wiki/Pell%27s_equation
#   https://projecteuler.net/problem=66

use 5.010;
use strict;
use warnings;

use Math::BigNum qw(:constant);
local $Math::BigNum::PREC = 10000;

use ntheory qw(is_power sqrtint);

sub quadratic_formula {
    my ($x, $y, $z) = @_;
    (-$y - sqrt($y**2 - 4 * $x * $z)) / (2 * $x);
}

sub sqrt_convergents {
    my ($n) = @_;

    my $x = sqrtint($n);
    my $y = $x;
    my $z = 1;

    my @convergents = ($x);

    do {
        $y = int(($x + $y) / $z) * $z - $y;
        $z = int(($n - $y * $y) / $z);
        push @convergents, int(($x + $y) / $z);
    } until (($y == $x) && ($z == 1));

    return @convergents;
}

sub continued_frac {
    my ($i, $c) = @_;
    $i == -1 ? 0 : 1 / ($c->[$i] + continued_frac($i - 1, $c));
}

sub solve {
    my ($d) = @_;

    my ($k, @c) = sqrt_convergents($d);
    my $period = @c;

    for (my ($i, $acc) = (0, 0) ; ; ++$i) {

        if ($i > $#c) {
            push @c, @c[0 .. $period - 1];
            $i = 2 * $i - 1;
        }

        my $x = continued_frac($i, [$k, @c])->denominator;
        my $y = quadratic_formula(-$d, 0, $x**2 - 1);

        if ($y > 0 and $y->is_int) {
            return ($x, $y);
        }
    }
}

foreach my $d (2 .. 20) {
    is_power($d, 2) && next;
    my ($x, $y) = solve($d);
    printf("x^2 - %2dy^2 = 1 \t minimum solution: x=%4d and y=%4d\n", $d, $x, $y);
}

__END__
x^2 -  2y^2 = 1      minimum solution: x=   3 and y=   2
x^2 -  3y^2 = 1      minimum solution: x=   2 and y=   1
x^2 -  5y^2 = 1      minimum solution: x=   9 and y=   4
x^2 -  6y^2 = 1      minimum solution: x=   5 and y=   2
x^2 -  7y^2 = 1      minimum solution: x=   8 and y=   3
x^2 -  8y^2 = 1      minimum solution: x=   3 and y=   1
x^2 - 10y^2 = 1      minimum solution: x=  19 and y=   6
x^2 - 11y^2 = 1      minimum solution: x=  10 and y=   3
x^2 - 12y^2 = 1      minimum solution: x=   7 and y=   2
x^2 - 13y^2 = 1      minimum solution: x= 649 and y= 180
x^2 - 14y^2 = 1      minimum solution: x=  15 and y=   4
x^2 - 15y^2 = 1      minimum solution: x=   4 and y=   1
x^2 - 17y^2 = 1      minimum solution: x=  33 and y=   8
x^2 - 18y^2 = 1      minimum solution: x=  17 and y=   4
x^2 - 19y^2 = 1      minimum solution: x= 170 and y=  39
x^2 - 20y^2 = 1      minimum solution: x=   9 and y=   2
