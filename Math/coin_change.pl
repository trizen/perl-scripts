#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 14 November 2015
# Website: https://github.com/trizen

# The classic coin-change problem

use 5.010;
use strict;
use warnings;

use List::Util qw(sum0);
no warnings qw(recursion);
use Math::BigNum qw(:constant);

my @denominations = (.01, .05, .1, .25, .5, 1, 2, 5, 10, 20, 50, 100);

sub change {
    my ($n, $pos, $solution) = @_;
    my $sum = sum0(@$solution);

    if ($sum == $n) {
        return $solution;    # found a solution
    }
    elsif ($sum > $n or $pos > $#denominations) {
        return;
    }

    (
        change($n, $pos + 1, $solution),
        change($n, $pos, [@$solution, $denominations[$pos]]),
    )
}

my $amount = 0.26;               # the amount of money

my @solutions = change($amount, 0, []);
print("All the possible solutions for $amount, are:\n");

my $best = $solutions[0];
foreach my $s (@solutions) {

    # Print the solutions
    print("\t[" . join(", ", @{$s}) . "]\n");

    # Find the best solution (which uses the minimum number of coins)
    if (@$s < @$best) {
        $best = $s;
    }
}

print("The best solution is: [", join(", ", @$best) . "]\n");
