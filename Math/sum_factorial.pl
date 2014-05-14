#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13th October 2013
# http://trizenx.blogspot.com

# This script generates sums of consecutive numbers for factorial numbers.

use 5.010;
use strict;
use warnings;

sub sum_x {
    my ($x, $y, $z) = @_;
    ($x + $y) * (($y - $x) / $z + 1) / 2;
}

sub factorial {
    my ($n) = @_;

    my $fact = 1;
    $fact *= $_ for 2 .. $n;

    $fact;
}

foreach my $i (1 .. 9) {
    my $fact = factorial($i);

  O: for (my $o = 1 ; $o <= int sqrt($fact) ; $o++) {
      N: for (my $n = 1 ; $n <= $fact ; $n++) {
          M: for (my $m = $n ; $m <= $fact ; $m++) {

                my $sum = sum_x($n, $m, $o);

                if ($sum == $fact) {
                    printf "%2d. %10d:%5d %10d .. %d\n", $i, $fact, $o, $n, $m;
                }
            }
        }

        last if $o >= 1;
    }

    say '';
}
