#!/usr/bin/perl

# Author: Trizen
# License: GPLv3
# Date: 27 September 2014
# http://github.com/trizen

# See also:
#   https://en.wikipedia.org/wiki/Wilson's_theorem

use 5.010;
use strict;
use warnings;

use Math::BigNum;
my $prime = Math::BigNum->new(3);
my $fac  = Math::BigNum->new(2);

say 2;    # print the first prime number

while (1) {
    if ($fac->inc->bmod($prime)->is_zero) {
        say $prime;
    }

    $fac->bmul($prime);
    $fac->bmul($prime->binc);
    $prime->binc;
}
