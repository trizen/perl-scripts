#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 08 February 2018
# https://github.com/trizen

# Farey rational approximation of a real number.

# See also:
#   https://en.wikipedia.org/wiki/Farey_sequence
#   https://en.wikipedia.org/wiki/Stern%E2%80%93Brocot_tree

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(:overload pi);

sub farey_approximation ($r, $eps = 1e-48) {

    my ($a, $b, $c, $d) = (0, 1, 1, 0);

    while (1) {
        my $m = ($a + $c) / ($b + $d);

        if ($m < $r) {
            ($a, $b) = $m->nude;
        }
        elsif ($m > $r) {
            ($c, $d) = $m->nude;
        }
        else {
            return $m;
        }

        if (abs($r - $m) <= $eps) {
            return $m;
        }
    }
}

say farey_approximation(pi);            #=> 2857198258041217165097342/909474452321624805685313
say farey_approximation(sqrt(2));       #=> 1572584048032918633353217/1111984844349868137938112
