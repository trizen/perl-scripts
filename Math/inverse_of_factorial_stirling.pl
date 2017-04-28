#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 18 September 2016
# Website: https://github.com/trizen

# The inverse of n factorial, based on the inverse of Stirling approximation.

# Formula from:
#   http://math.stackexchange.com/questions/430167/is-there-an-inverse-to-stirlings-approximation

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(:overload tau e factorial);

use constant S => tau->sqrt->log;
use constant T => tau->root(-2.0 * e);

sub inv_fac_W {
    my ($n) = @_;
    my $L = log($n) - S;
    $L / ($L / e)->LambertW - 0.5;
}

sub inv_fac_lgrt {
    my ($n) = @_;
    (T * $n**(1 / e))->lgrt * e - 0.5;
}

for my $n (1 .. 100) {

    my $f = factorial($n);
    my $i = inv_fac_W($f);
    my $j = inv_fac_lgrt($f);

    printf("F(%2s!) =~ %s\n", $n, $i);

    if ($i->round(-20) != $j->round(-20)) {
        die "$i != $j";
    }

    if ($i->round != $n) {
        die "However that is incorrect! (expected: $n -- got ", $i->round, ")";
    }
}
