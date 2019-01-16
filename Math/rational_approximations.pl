#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 16 January 2019
# https://github.com/trizen

# Simple and efficient algorithm for finding the first continued-fraction convergents to a given real constant.

# Continued-fraction convergents for PI:
#   https://oeis.org/A002485
#   https://oeis.org/A002486

# See also:
#   https://en.wikipedia.org/wiki/Continued_fraction

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(:overload float);

sub rational_approximations ($x, $callback, $first = 10) {

    $x = float($x) || return;

    my ($n1, $n2) = (0, 1);
    my ($d1, $d2) = (1, 0);

    my $f = $x;

    for (1 .. $first) {
        my $z = int($f);

        $n1 += $n2 * $z;
        $d1 += $d2 * $z;

        ($n1, $n2) = ($n2, $n1);
        ($d1, $d2) = ($d2, $d1);

        $callback->($n2 / $d2);

        $f -= $z;
        $f || last;
        $f = 1 / $f;
    }
}

my $x = atan2(0, -1);
my $f = sub ($q) { say "PI =~ $q" };

rational_approximations($x, $f, 20);

__END__
PI =~ 3
PI =~ 22/7
PI =~ 333/106
PI =~ 355/113
PI =~ 103993/33102
PI =~ 104348/33215
PI =~ 208341/66317
PI =~ 312689/99532
PI =~ 833719/265381
PI =~ 1146408/364913
PI =~ 4272943/1360120
PI =~ 5419351/1725033
PI =~ 80143857/25510582
PI =~ 165707065/52746197
PI =~ 245850922/78256779
PI =~ 411557987/131002976
PI =~ 1068966896/340262731
PI =~ 2549491779/811528438
PI =~ 6167950454/1963319607
PI =~ 14885392687/4738167652
