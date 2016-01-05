#!/usr/bin/perl

# Riemann's J function
# J(x) = Σ 1/k π(⌊x^(1/k)⌋)

use strict;
use warnings;

use ntheory qw(prime_count);

sub J {
    my ($x) = @_;

    my $sum = 0;

    my $k = 1;
    while (1) {
        my $pi = prime_count(int($x**(1 / $k)));
        last if $pi == 0;
        $sum += 1 / $k++ * $pi;
    }

    $sum;
}

foreach my $k (1 .. 99) {
    printf("J(%2d) = %s\n", $k, J($k));
}
