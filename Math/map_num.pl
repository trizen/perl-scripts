#!/usr/bin/perl

# Author: Trizen
# License: GPLv3
# Date: 08th October 2013
# http://trizenx.blogspot.com

# Map an amount of numbers in a given interval

use 5.010;
use strict;
use warnings;

sub map_num {
    my ($amount, $from, $to) = @_;

    my $diff = $to - $from;
    my $step = $diff / $amount;

    return if $step == 0;

    my @nums;
    for (my $i = $from ; $i <= $to ; $i += $step) {
        push @nums, $i;
    }

    return @nums;
}

say join "\n", map_num(10, 4, 5);
