#!/usr/bin/perl

use 5.014;

OUTER: for (my $i = 3 ; ; $i += 2) {
    foreach my $j (2 .. sqrt($i)) {
        $i % $j || next OUTER;
    }
    say $i;
}
