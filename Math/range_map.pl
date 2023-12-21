#!/usr/bin/perl

# Map a given value from a given range into another range.

use 5.010;
use strict;
use warnings;

sub range_map {
    my ($value, $in_min, $in_max, $out_min, $out_max) = @_;
    ($value - $in_min) * ($out_max - $out_min) / ($in_max - $in_min) + $out_min;
}

say range_map(5, 1, 10, 0, 4);    #=> 1.777... (maps the value 5 from range [1, 10] to range [0, 4])
say range_map(9, 1, 10, 1, 5);    #=> 4.555... (maps the value 9 from range [1, 10] to range [1, 5])
