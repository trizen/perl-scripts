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

#
## Real base and complex exponent
#
sub complex_power {
    my ($x, $r, $i) = @_;

    (
        $x**$r * cos(log($x) * $i),
        $x**$r * sin(log($x) * $i),
    )
}

#
## Complex base and complex exponent
#
sub complex_power2 {
    my ($x, $y, $r, $i) = @_;

     ($x, $y) = (log($x*$x + $y*$y) / 2, atan2($y, $x));    # log($x + $y*i)
     ($x, $y) = ($x*$r - $y*$i, $x*$i + $y*$r);             # ($x + $y*i) * ($r + $i*i)

     (exp($x) * cos($y), exp($x) * sin($y));                # exp($x + $y*i)
}

#
## Example for 12^(3+4i)
#

{
    # base
    my $x = 12;

    # exponent
    my $r = 3;
    my $i = 4;

    my ($real, $imag) = complex_power($x, $r, $i);

    say "$x^($r + $i*i) = $real + $imag*i";   #=> -1503.99463080925 + -850.872581822307*i
}

#
## Example for (5+2i)^(3+7i)
#

{
    # base
    my $x = 5;
    my $y = 2;

    # exponent
    my $r = 3;
    my $i = 7;

    my ($real, $imag) = complex_power2($x, $y, $r, $i);

    say "($x + $y*i)^($r + $i*i) = $real + $imag*i";    #=> 10.1847486230437 + 3.84152292303168*i
}
