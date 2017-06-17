#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 17 June 2017
# https://github.com/trizen

# Prime product, related to the zeta function.

# ___
# | | (p^(2n) - 1) / (p^(2n) + 1) = {2/5, 6/7, 691/715, 7234/7293, 523833/524875, ...}
#  p

# Example:
#   Product_{n >= 1} (prime(n)^2 - 1)/(prime(n)^2 + 1) = 2/5

use 5.010;
use strict;
use warnings;

use ntheory qw(forprimes);

my $n = 2;

{
    my $prod = 1;
    forprimes {
        $prod *= ($_**$n + 1) / ($_**$n - 1);
    } 1e7;

    say $prod;
}

{
    my $prod = 1;
    forprimes {
        $prod *= ($_**$n + 1) / ($_**$n - 1);
    } 1e8;

    say $prod;
    say 1 / $prod;
}

__END__
2.49999997066443
2.49999999690776
0.400000000494758
