#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 31 August 2016
# Edit: 07 February 2018
# License: GPLv3
# https://github.com/trizen

# Find the smallest solution in positive integers to the Pell equation: x^2 - d*y^2 = ±1, where `d` is known.

# See also:
#   https://en.wikipedia.org/wiki/Pell%27s_equation
#   https://projecteuler.net/problem=66

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(is_square isqrt);

sub sqrt_convergents {
    my ($n) = @_;

    my $x = isqrt($n);
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

sub cfrac_denominator {
    my (@cfrac) = @_;

    my ($f1, $f2) = (0, 1);

    foreach my $n (@cfrac) {
        ($f1, $f2) = ($f2, $n * $f2 + $f1);
    }

    return $f1;
}

sub solve_pell {
    my ($d) = @_;

    return if is_square($d);

    my ($k, @period) = sqrt_convergents($d);

    my @solutions;

    my $x = cfrac_denominator($k, @period);
    my $p1 = 4 * $d * ($x * $x + 1);

    if (is_square($p1)) {
        push @solutions, [$x, isqrt($p1) / (2 * $d)];
        $x = cfrac_denominator($k, @period, @period);
    }

    my $p2 = 4 * $d * ($x * $x - 1);
    push @solutions, [$x, isqrt($p2) / (2 * $d)];

    return @solutions;
}

foreach my $d (1 .. 30) {

    my @solutions = solve_pell($d);

    foreach my $solution (@solutions) {
        my ($x, $y) = @$solution;
        printf("x^2 - %2dy^2 = %2d    minimum solution: x=%5s and y=%5s\n", $d, $x**2 - $d * $y**2, $x, $y);
    }
}

__END__
x^2 -  2y^2 = -1    minimum solution: x=    1 and y=    1
x^2 -  2y^2 =  1    minimum solution: x=    3 and y=    2
x^2 -  3y^2 =  1    minimum solution: x=    2 and y=    1
x^2 -  5y^2 = -1    minimum solution: x=    2 and y=    1
x^2 -  5y^2 =  1    minimum solution: x=    9 and y=    4
x^2 -  6y^2 =  1    minimum solution: x=    5 and y=    2
x^2 -  7y^2 =  1    minimum solution: x=    8 and y=    3
x^2 -  8y^2 =  1    minimum solution: x=    3 and y=    1
x^2 - 10y^2 = -1    minimum solution: x=    3 and y=    1
x^2 - 10y^2 =  1    minimum solution: x=   19 and y=    6
x^2 - 11y^2 =  1    minimum solution: x=   10 and y=    3
x^2 - 12y^2 =  1    minimum solution: x=    7 and y=    2
x^2 - 13y^2 = -1    minimum solution: x=   18 and y=    5
x^2 - 13y^2 =  1    minimum solution: x=  649 and y=  180
x^2 - 14y^2 =  1    minimum solution: x=   15 and y=    4
x^2 - 15y^2 =  1    minimum solution: x=    4 and y=    1
x^2 - 17y^2 = -1    minimum solution: x=    4 and y=    1
x^2 - 17y^2 =  1    minimum solution: x=   33 and y=    8
x^2 - 18y^2 =  1    minimum solution: x=   17 and y=    4
x^2 - 19y^2 =  1    minimum solution: x=  170 and y=   39
x^2 - 20y^2 =  1    minimum solution: x=    9 and y=    2
x^2 - 21y^2 =  1    minimum solution: x=   55 and y=   12
x^2 - 22y^2 =  1    minimum solution: x=  197 and y=   42
x^2 - 23y^2 =  1    minimum solution: x=   24 and y=    5
x^2 - 24y^2 =  1    minimum solution: x=    5 and y=    1
x^2 - 26y^2 = -1    minimum solution: x=    5 and y=    1
x^2 - 26y^2 =  1    minimum solution: x=   51 and y=   10
x^2 - 27y^2 =  1    minimum solution: x=   26 and y=    5
x^2 - 28y^2 =  1    minimum solution: x=  127 and y=   24
x^2 - 29y^2 = -1    minimum solution: x=   70 and y=   13
x^2 - 29y^2 =  1    minimum solution: x= 9801 and y= 1820
x^2 - 30y^2 =  1    minimum solution: x=   11 and y=    2
