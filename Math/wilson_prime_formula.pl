#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 27 September 2014
# Edit: 15 May 2021
# http://github.com/trizen

# See also:
#   https://en.wikipedia.org/wiki/Wilson's_theorem

use 5.020;
use strict;
use warnings;

use Math::AnyNum qw(factorial);
use experimental qw(signatures);

sub is_wilson_prime($n) {
    factorial($n-1) % $n == $n-1;
}

for my $n (2..100) {
    if (is_wilson_prime($n)) {
        print($n, ", ");
    }
}
