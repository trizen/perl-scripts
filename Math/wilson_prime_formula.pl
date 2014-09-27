#!/usr/bin/perl

# Author: Trizen
# License: GPLv3
# Date: 27 September 2014
# http://github.com/trizen

# Requires: Math::BigInt::GMP

use 5.010;
use strict;
use warnings;

use Math::BigInt (only => 'GMP');
my $f = Math::BigInt->new(2);

while (1) {
    if (((($f - 1)->bfac + 1)->bmod($f))->is_zero) {
        say $f;
    }
    $f->binc;
}
