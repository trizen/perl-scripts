#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 26 July 2015
# Website: https://github.com/trizen

# Generate a "reversed" number triangle.

my $rows = 6;
my @arr  = ([1]);

my $n = 1;
foreach my $i (1 .. $rows) {

    foreach my $j (reverse 0 .. $#arr) {
        push @{$arr[$j]}, ++$n;
        unshift @{$arr[$j]}, ++$n;
    }

    unshift @arr, [++$n];
}

foreach my $row (@arr) {
    print " " x (3 * $rows--);
    print map { sprintf "%3d", $_ } @{$row};
    print "\n";
}
