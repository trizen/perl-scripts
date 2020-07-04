#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 10 May 2016
# Website: https://github.com/trizen

# Continued fraction constant for primes.

use 5.010;
use strict;
use ntheory qw(nth_prime);

sub prime_constant {
    my ($i, $limit) = @_;
    my $p = nth_prime($i);
    $limit > 0 ? ($p / ($p + prime_constant($i + 1, $limit - 1))) : 0;
}

my $pc = prime_constant(1, 10000);

say $pc;
say 1 / (1 + $pc);    # "1" is considered prime here

__END__
0.71961651193526
0.581525004592215
