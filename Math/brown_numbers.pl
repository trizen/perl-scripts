#!/usr/bin/perl

# See: http://www.youtube.com/watch?v=-Djj6pfR9KU

use 5.010;
use strict;
use warnings;

use bignum ('precision' => -128);

sub factorial {
    state $x = 1;
    $x *= $_[0];
}

for my $i (1 .. 60) {
    my $sqrt = sqrt(factorial($i) + 1);
    next if $sqrt != int($sqrt);
    printf("(%d, %d)\n", int($sqrt), $i);
}
