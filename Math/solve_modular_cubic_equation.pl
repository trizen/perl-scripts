#!/usr/bin/perl

# Author: Trizen
# Date: 04 May 2022
# https://github.com/trizen

# Solve modular quadratic equations of the form:
#   a*x^3 + b*x^2 + c*x + d == 0 (mod m)

# Work in progress! Not all solutions are found.
# Sometimes, no solution is found, even if solutions do exist...

# See also:
#   https://en.wikipedia.org/wiki/Cubic_equation

use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use List::Util qw(uniq);
use Math::AnyNum qw(:overload);
use experimental qw(signatures);

sub modular_cubic_equation ($A, $B, $C, $D, $M) {

    my $D0 = ($B * $B - 3 * $A * $C) % $M;
    my $D1 = (2 * $B**3 - 9 * $A * $B * $C + 27 * $A * $A * $D) % $M;

    my @S2 = allsqrtmod(($D1**2 - 4 * $D0**3) % (4 * $M), (4 * $M));
    my @S3;

    foreach my $s2 (@S2) {
        foreach my $r ($D1 + $s2, $D1 - $s2) {
            foreach my $s3 (allrootmod(($r / 2) % $M, 3, $M)) {
                my $nu = -($B + $s3 + $D0 / $s3) % $M;
                my $de = (3 * $A);

                my $x = ($nu / $de) % $M;
                if (($A * $x**3 + $B * $x**2 + $C * $x + $D) % $M == 0) {
                    push @S3, $x;
                }
            }
        }
    }

    return sort { $a <=> $b } uniq(@S3);
}

say join ' ', modular_cubic_equation(5, 3, -12, -640196464320, 432);        #=> 261
say join ' ', modular_cubic_equation(1, 1, 1,   -10**10 + 42,  10**10);     #=> 9709005706
say join ' ', modular_cubic_equation(1, 4, 6,   13 - 10**10,   10**10);     #=> 8614398889
say join ' ', modular_cubic_equation(1, 1, 1,   -10**10 - 10,  10**10);     #=> 8013600910
