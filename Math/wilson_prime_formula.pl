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
my $prime = Math::BigInt->new(2);
my $fact = Math::BigInt->new(1);

while(1) {
     if ($prime % 2 and ($fact + 1)->bmod($prime)->is_zero) {
        say $prime;
    }
    $fact->bmul($prime->binc - 1);
}

__END__
if (((($f - 1)->bfac + 1)->bmod($f))->is_zero) {
    say $f;
}
