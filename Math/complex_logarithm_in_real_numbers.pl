#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 11 December 2017
# https://github.com/trizen

# Identity for computing the natural logarithm of a complex number, in real numbers, with the identity:
#
#   log(a+b*i) = log(a^2 + b^2)/2 + atan(b/a)*i
#

use 5.010;
use strict;
use warnings;

sub complex_log {
    my ($re, $im) = @_;

    (
        log($re**2 + $im**2)/2,
        atan2($im, $re)
    );
}

#
## Example for log(3+5i)
#

my $re = 3;
my $im = 5;

my ($real, $imag) = complex_log($re, $im);

say "log($re + $im*i) = $real + $imag*i";   #=> 1.76318026230808 + 1.03037682652431*i
