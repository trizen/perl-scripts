#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 31 July 2017
# Edit: 01 January 2018
# https://github.com/trizen

# Binomial summation in integers of an expression of the form: (a + b*sqrt(-1))^n

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(:overload binomial);

sub imaginary_binomial_sum {
    my ($c, $d, $n) = @_;

    my $re = 0;
    my $im = 0;

    foreach my $k (0 .. $n) {
        my $t = binomial($n, $k) * $c**($n - $k) * $d**$k;

        if ($k % 4 == 0) {
            $re += $t;
        }
        elsif ($k % 4 == 1) {
            $im += $t;
        }
        elsif ($k % 4 == 2) {
            $re -= $t;
        }
        elsif ($k % 4 == 3) {
            $im -= $t;
        }
    }

    return ($re, $im);
}

#
## Example for: (2 + 3*sqrt(-1))^10
#

my $c = 2;
my $d = 3;
my $n = 10;

my ($re, $im) = imaginary_binomial_sum($c, $d, $n);

say "($c + $d*sqrt(-1))^$n = ($re, $im)";       #=> (-341525, -145668)
