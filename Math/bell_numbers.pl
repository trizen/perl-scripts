#!/usr/bin/perl

# Fast algorithm for computing the Bell numbers, using Aitken's array.

# See also:
#   https://en.wikipedia.org/wiki/Bell_number

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

#use Math::AnyNum qw(:overload);

sub bell_number ($n) {

    my @acc;
    my $bell = 1;

    foreach my $k (1 .. $n) {
        my $t = $bell;

        foreach my $i (0 .. $#acc) {
            $t += $acc[$i];
            $acc[$i] = $t;
        }

        unshift(@acc, $bell);
        $bell = $acc[-1];
    }

    $bell;
}

say join ', ', map { bell_number($_) } 0 .. 14;

__END__
1, 1, 2, 5, 15, 52, 203, 877, 4140, 21147, 115975, 678570, 4213597, 27644437, 190899322
