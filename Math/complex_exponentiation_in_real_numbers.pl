#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 13 August 2017
# https://github.com/trizen

# Identity for complex exponentiation in real numbers, based on the identity:
#
#   exp(x*i) = cos(x) + sin(x)*i
#

use 5.010;
use strict;
use warnings;

sub complex_power {
    my ($x, $r, $i) = @_;

    (
        $x**$r * cos(log($x) * $i),
        $x**$r * sin(log($x) * $i),
    )
}

#
## Example for 12^(3+4i)
#

my $x = 12;
my $r = 3;
my $i = 4;

my ($real, $imag) = complex_power($x, $r, $i);

say "$x^($r + $i*i) = $real + $imag*i";   #=> -1503.99463080925 + -850.872581822307*i
