#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 25 December 2012
# https://github.com/trizen

sub next_power_of_two {
    return 2 << log($_[0]) / log(2);
}

for my $i (1, 31, 55, 129, 446, 9924) {
    print next_power_of_two($i), "\n";
}
