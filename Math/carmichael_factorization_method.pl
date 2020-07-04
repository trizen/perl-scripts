#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 17 March 2019
# https://github.com/trizen

# A new factorization method for numbers with exactly three distinct prime factors of the form:
#
#   n = a * (a+x) * (a+y)
#   n = a * ((a±1)*x ± 1) *  ((a±1)*y ± 1)
#
# for x,y relatively small.

# Many Carmichael numbers and Lucas pseudoprimes are of this form and can be factorized relatively fast by this method.

# See also:
#   https://en.wikipedia.org/wiki/Cubic_function

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(lastfor forcomb);
use Math::AnyNum qw(:overload isqrt icbrt round gcd);

#<<<
sub solve_cubic_equation ($a, $b, $c, $d) {

    my $p = (3*$a*$c - $b*$b) / (3*$a*$a);
    my $q = (2 * $b**3 - 9*$a*$b*$c + 27*$a*$a*$d) / (27 * $a**3);

    my $t = (icbrt(-($q/2) + isqrt(($q**2 / 4) + ($p**3 / 27))) +
             icbrt(-($q/2) - isqrt(($q**2 / 4) + ($p**3 / 27))));

    my $x = round($t - $b/(3*$a));

    return $x;
}
#>>>

sub carmichael_factorization ($n, $l = 2, $h = 23) {

    my $factor = 1;

    my sub try_parameters ($a, $b, $c) {

        my $t = solve_cubic_equation($a, $b, $c, -$n);
        my $g = gcd($t, $n);

        if ($g > 1 and $g < $n) {
            $factor = $g;
            return 1;
        }
    }

    my @range = ($l .. $h);

    forcomb {
        my ($x, $y) = @range[@_];

        my $a = $x * $y;
        my $b = 2 * $a - $x - $y;
        my $c = $a - $x - $y + 1;

        try_parameters($a, $b,      $c)  and do { lastfor, return $factor };
        try_parameters($a, -$b,     $c)  and do { lastfor, return $factor };
        try_parameters(1,  $x + $y, $a)  and do { lastfor, return $factor };
        try_parameters($a, $y - $x, -$c) and do { lastfor, return $factor };

        try_parameters($a, (+2 * $y + 1) * $x + $y, ($y + 1) * $x + ($y + 1)) and do { lastfor, return $factor };
        try_parameters($a, (-2 * $y - 1) * $x - $y, ($y + 1) * $x + ($y + 1)) and do { lastfor, return $factor };
    } scalar(@range), 2;

    return $factor;
}

say carmichael_factorization(7520940423059310542039581);                                          #=> 79443853
say carmichael_factorization(1000000032900000272110000405099);                                    #=> 10000000103
say carmichael_factorization(570115866940668362539466801338334994649);                            #=> 4563211789627
say carmichael_factorization(8325544586081174440728309072452661246289);                           #=> 11153738721817
say carmichael_factorization(1169586052690021349455126348204184925097724507);                     #=> 166585508879747
say carmichael_factorization(61881629277526932459093227009982733523969186747);                    #=> 1233150073853267
say carmichael_factorization(173315617708997561998574166143524347111328490824959334367069087);    #=> 173823271649325368927
