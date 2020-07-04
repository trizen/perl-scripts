#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

sub zeta {
    my ($n) = @_;
    my $sum = 0;

    foreach my $i (1 .. 1000000) {
        $sum += (1 / $i**$n);
    }

    $sum;
}

say zeta(2);
