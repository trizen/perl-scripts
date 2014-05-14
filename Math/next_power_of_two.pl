#!/usr/bin/perl

# Author: Trizen
# License: GPLv3
# Date: 25 December 2012
# http://trizen.googlecode.com

sub next_power_of_two {
    return 2 << log($_[0]) / log(2);
}

for my $i (1, 31, 55, 129, 446, 9924) {
    print next_power_of_two($i), "\n";
}
