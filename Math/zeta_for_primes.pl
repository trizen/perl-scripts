#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 22 September 2015
# Website: https://github.com/trizen

# Zeta-prime formula
#   Sum of 1/P(n)^p
# where P(n) is a prime number and p is a positive integer.

use 5.010;
use strict;
use warnings;

use ntheory qw(nth_prime);

my @sums;
foreach my $i (1 .. 100000) {
    foreach my $p (1 .. 10) {
        $sums[$p - 1] += 1 / nth_prime($i)**$p;
    }
}

foreach my $p (0 .. $#sums) {
    printf("zp(%d) = %s\n", $p + 1, $sums[$p]);
}

__END__
#
## From i=1..1000000
#
zp(1) = 3.06821904805445
zp(2) = 0.452247416351722
zp(3) = 0.174762639299271
zp(4) = 0.0769931397642436
zp(5) = 0.035755017483924
zp(6) = 0.0170700868506365
zp(7) = 0.00828383285613359
zp(8) = 0.00406140536651783
zp(9) = 0.00200446757496245
zp(10) = 0.00099360357443698
