#!/usr/bin/perl

# A fast algorithm for computing the n-th Bell number modulo a native integer.

# See also:
#   https://oeis.org/A325630 -- Numbers k such that Bell(k) == 0 (mod k).
#   https://en.wikipedia.org/wiki/Bell_number

use 5.020;
use strict;
use warnings;

use Math::GMPz;
use ntheory qw(addmod);
use experimental qw(signatures);

sub bell_number ($n, $m) {

    my @acc;

    my $t    = 0;
    my $bell = 1;

    foreach my $k (1 .. $n) {

        $t = $bell;

        foreach my $j (@acc) {
            $t = addmod($t, $j, $m);
            $j = $t;
        }

        unshift @acc, $bell;
        $bell = $acc[-1];
    }

    $bell;
}

say bell_number(35,  35);      #=> 0
say bell_number(35,  1234);    #=> 852
say bell_number(123, 4171);    #=> 3567
