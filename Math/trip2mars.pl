#!/usr/bin/perl

# Author: Trizen
# License: GPLv3
# Date: 15 October 2013
# http://trizenx.blogspot.com

# This program solves the "Trip to Mars" problem
# See: http://www.youtube.com/watch?v=k-zrgRv9tFU

use 5.010;
use strict;
use warnings;

my %max = (
           hours  => 0,
           games  => 0,
           movies => 0,
          );

foreach my $x (0 .. 200) {
    foreach my $y (0 .. 200 - $x) {

        next if 8 * $x + 3 * $y > 1200;
        next if 0.2 * $x + 0.8 * $y > 130;

        my $hours = 4 * $x + 2 * $y;

        if ($hours > $max{hours}) {
            $max{hours}  = $hours;
            $max{games}  = $x;
            $max{movies} = $y;
        }
    }
}

say "To maximize the time on breaks, you need to buy $max{games} games and $max{movies} movies.";
