#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 14 November 2017
# https://github.com/trizen

# Conversion of a fraction to a decimal-expansion with an arbitrary number of decimals, using Math::AnyNum.

use 5.020;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(bernfrac ilog10 float);

sub frac2dec ($x, $p = 32) {
    my $size = ilog10(abs($x)) + 1;
    $x->as_dec($size + $p);
}

my $n = bernfrac(60);

say frac2dec($n);        #=> -21399949257225333665810744765191097.39267415116172387457421830769266
say frac2dec($n, 48);    #=> -21399949257225333665810744765191097.392674151161723874574218307692659887265915822235
