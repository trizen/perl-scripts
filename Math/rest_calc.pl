#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 14 January 2013
# https://github.com/trizen

# Calculates how to give back some amount of money.

use 5.010;
use strict;
use warnings;

my @steps = (500, 200, 100, 50, 10, 5, 1, 0.5, 0.1, 0.05, 0.01);

my $rest = shift // 9999.99;

foreach my $i (@steps) {
    my $x = 0;
    while ($rest >= $i) {
        ++$x;
        $rest -= $i;
    }
    if ($x) {
        say "$x x $i";
        last if $rest == 0;
    }
}
