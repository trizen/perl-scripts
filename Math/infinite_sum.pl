#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

sub sum {
    my $sum = 0;

    foreach my $n(1..1000000) {
        $sum += (1 / $n**3);
    }

    $sum;
}

say sum();
