#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 09 May 2016
# Website: https://github.com/trizen

# Generator of perfect numbers, using the fact that
# the Mth triangular number, where M is a Mersenne
# prime in the form 2^p-1, gives us a perfect number.

# See also: https://en.wikipedia.org/wiki/Perfect_number

use 5.010;
use strict;
use warnings;

use Math::BigNum;
use ntheory qw(forprimes is_prime);

forprimes {
    my $n = Math::BigNum->one << $_;
    if (is_prime($n - 1)) {
        say "2^($_-1) * (2^$_-1) = ", $n * ($n - 1) / 2;
    }
} 1, 100;
