#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 22 August 2015
# Website: https://github.com/trizen

# A new algorithm to compute n! in int(n/2) iterations, instead of n.

use 5.010;
use strict;
use warnings;

#----------------------------------------------
## The algorithm
#----------------------------------------------
# 6! = 1 * 2 * 3 * 4 * 5 * 6
#
#    = 1*6 * 2*5 * 3*4
#    =   6 *  10 *  12
#
#    = (7*1 - 1^2) * (7*2 - 2^2) * (7*3 - 3^2)
#    =     1*(7-1) *     2*(7-2) *     3*(7-3)
#----------------------------------------------

sub factorial {
    my ($n) = @_;

    use integer;

    my $p = 1;
    my $d = $n / 2;
    my $m = $n % 2;
    my $k = $n + 1;

    foreach my $i (1 .. $d) {
        $p *= $i * ($k - $i);
    }

    $m ? $p * ($k / 2) : $p;
}

foreach my $i (1 .. 15) {
    say "$i! = ", factorial($i);
}
