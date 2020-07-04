#!/usr/bin/perl

# Efficient implementation of Ramanujan's sum.

use 5.010;
use strict;
use warnings;

use ntheory qw(gcd euler_phi moebius);

sub ramanujan_sum {
    my ($n, $k) = @_;

    my $g = $k / gcd($n, $k);
    my $m = moebius($g);

    $m * euler_phi($k) / euler_phi($g);
}

foreach my $n (1 .. 30) {
    say ramanujan_sum($n, $n**2);
}
