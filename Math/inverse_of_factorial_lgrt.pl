#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 18 September 2016
# Website: https://github.com/trizen

# The inverse of n factorial, based on the inverse of Stirling approximation,
# computed with the `lgrt()` function, which calculates the logarithmic-root of n.

use 5.010;
use strict;
use warnings;

use Math::BigNum qw(:constant pi e);

use constant S => (2 * pi)**(-1 / (2 * e));

sub lgrt {
    my ($c) = @_;

    my $p = 1 / 10**($Math::BigNum::PREC / 4);
    my $d = log($c);

    my $x = 1;
    my $y = 0;

    while (abs($x - $y) > $p) {
        $y = $x;
        $x = ($x + $d) / (1 + log($x));
    }

    $x;
}

sub inverse_of_factorial {
    lgrt(S * $_[0]**(1 / e)) * e - 0.5;
}

#
## Tests
#

#<<<
my @tests = (
    [3, 6],
    [4, 24],
    [5, 120],
    [10, 3628800],
    [15, 1307674368000],
);
#>>>

foreach my $test (@tests) {
    my ($n, $f) = @{$test};

    my $i = inverse_of_factorial($f);

    printf("F(%13s) =~ %s\n", $f, $i);

    if (sprintf('%.0f', $i) != $n) {
        warn "However that is incorrect! (expected: $n)";
    }
}
