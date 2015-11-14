#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 14 November 2015
# Website: https://github.com/trizen

# The classic coin-change problem

use 5.010;
use strict;
use warnings;

no warnings qw(recursion);
#use bignum (try => 'GMP');         # uncomment this line for better floating-point precision

my @denominations = (.01, .05, .1, .25, .5, 1, 2, 5, 10, 20, 50, 100);

sub sum {
    my (@list) = @_;

    my $sum = 0;
    foreach my $num (@list) {
        $sum += $num;
    }

    return $sum;
}

sub change {
    my ($n, $pos, $coins_so_far) = @_;

    my $sum = sum(@$coins_so_far);

    if ($sum == $n) {
        return $coins_so_far;    # found a solution
    }
    elsif ($sum > $n or $pos > $#denominations) {
        return;
    }

    (change($n, $pos, [@$coins_so_far, $denominations[$pos]]),
     change($n, $pos + 1, $coins_so_far));
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
