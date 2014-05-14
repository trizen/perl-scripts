#!/usr/bin/perl

# See: http://www.youtube.com/watch?v=-Djj6pfR9KU

use 5.010;
#use bigint;
#use integer;

sub factorial {
    state $x = 1;
    return $x *= $_[0];
}

for my $i (1 .. 1000) {
    my $sqrt = sqrt(factorial($i) + 1);
    next if $sqrt != int($sqrt);
    for my $j (1 .. 1000) {
        if ($sqrt == $j) {
            print "($j, $i)\n";
        }
    }
}
