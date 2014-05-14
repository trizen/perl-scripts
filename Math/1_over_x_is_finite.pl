#!/usr/bin/perl

# Author: Trizen
# License: GPLv3
# Date: 25 December 2012
# http://trizen.googlecode.com

# Checks if 1/x is finite or infinite.

# See also: http://perlmonks.org/index.pl?node_id=1006283

use 5.010;
use strict;
use warnings;

sub is_finite {
    my ($x) = @_;
    $x || return;
    $x /= 5 while $x % 5 == 0;
    return !($x & $x - 1);
}

foreach my $i (1 .. 20) {
    printf "%-4s is finite: %d\n", "1/$i", is_finite($i);
}
