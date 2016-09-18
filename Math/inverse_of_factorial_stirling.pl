#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 17 September 2016
# Website: https://github.com/trizen

# The inverse of n factorial, based on the inverse of Stirling approximation.

# Formula from:
#   http://math.stackexchange.com/questions/430167/is-there-an-inverse-to-stirlings-approximation

use 5.010;
use strict;
use warnings;

use ntheory qw(LambertW Pi);

use constant S => log(sqrt(2 * Pi()));

sub inverse_of_factorial {
    my $l = log($_[0]) - S;
    $l / LambertW(1 / exp(1) * $l) - 0.5;
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
