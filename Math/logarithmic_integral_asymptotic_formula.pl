#!/usr/bin/perl

# Very good asymptotic formula for Li(x), due to Cesaro.

use 5.010;
use strict;
use warnings;

use ntheory qw(factorial);

my $x = 1e9;

my $sum = 0;
foreach my $n (1 .. log($x)) {
    $sum += factorial($n - 1) * $x / log($x)**$n;
}
say $sum;    #=> 50849234.742179
