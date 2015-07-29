#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 26 July 2015
# Website: https://github.com/trizen

# Generate a set of interesting numeric triangles.

use 5.010;
use strict;
use warnings;

sub triangle {
    my ($rows, $type) = @_;

    my @triangle = ([1]);

    my $n = 1;
    foreach my $i (1 .. $rows) {

        if ($type == 1) {
            foreach my $j (0 .. $#triangle) {
                push @{$triangle[$j]}, ++$n;
                unshift @{$triangle[$j]}, ++$n;
            }
        }
        elsif ($type == 2) {
            foreach my $j (reverse 0 .. $#triangle) {
                push @{$triangle[$j]}, ++$n;
                unshift @{$triangle[$j]}, ++$n;
            }
        }
        elsif ($type == 3) {
            foreach my $j (0 .. $#triangle) {
                unshift @{$triangle[$j]}, ++$n;
            }
            foreach my $j (reverse 0 .. $#triangle) {
                push @{$triangle[$j]}, ++$n;
            }
        }
        elsif ($type == 4) {
            foreach my $j (reverse 0 .. $#triangle) {
                unshift @{$triangle[$j]}, ++$n;
            }
            foreach my $j (0 .. $#triangle) {
                push @{$triangle[$j]}, ++$n;
            }
        }
        else {
            die "Invalid type: $type";
        }

        unshift @triangle, [++$n];
    }

    return \@triangle;
}

my $width = 4;
my $rows  = 8;

foreach my $i (1 .. 4) {
    my $triangle = triangle($rows, $i);

    foreach my $i (0 .. $#{$triangle}) {
        my $row = $triangle->[$i];
        print " " x ($width * ($rows - $i));
        print map { sprintf "%*d", $width, $_ } @{$row};
        print "\n";
    }
    print "-" x ($width * ($rows + 1) * 2 - $width), "\n";
}
