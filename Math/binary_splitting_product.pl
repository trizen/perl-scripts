#!/usr/bin/perl

# Compute the product of a list of numbers, using binary splitting.

# See also:
#   https://en.wikipedia.org/wiki/Binary_splitting

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

sub binsplit_product ($s, $n, $m) {
    $n > $m  and return 1;
    $n == $m and return $s->[$n];
    my $k = ($n + $m) >> 1;
    __SUB__->($s, $n, $k) * __SUB__->($s, $k + 1, $m);
}

foreach my $n (1 .. 10) {
    my @list = (1 .. $n);
    printf "%2d! = %s\n", $n, binsplit_product(\@list, 0, $#list);
}
