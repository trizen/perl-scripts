#!/usr/bin/perl

# Author: Trizen

use 5.010;

my $format = "%20s ** %-20s = %s\n";

for my $x (2 .. 10) {
    for my $y (2 .. 10) {
        my $num = $x**$y;

        printf($format, $x, $y, $num);

        my $sqrt = $num;
        for (1 .. $y - 1) {
            $sqrt = sqrt($sqrt);
        }
        my $pow = 2**int($y - 1) / $y;
        printf($format, $sqrt, $pow, $sqrt**$pow);
        say "-" x 80;
    }
}
