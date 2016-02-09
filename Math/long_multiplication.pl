#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 09 July 2015
# Website: https://github.com/trizen

# A creative algorithm for arbitrary long integer multiplication.

use 5.010;
use strict;
use warnings;

use integer;
use List::Util qw(sum);

sub long_multiplication {
    my ($x, $y) = @_;

    use integer;
    if (length($x) < length($y)) {
        ($y, $x) = ($x, $y);
    }

    if ($x eq '0' or $y eq '0') {
        return '0';
    }

    my @x = reverse split //, $x;
    my @y = reverse split //, $y;

    my $xlen = $#x;
    my $ylen = $#y;

    my @map;
    my $mem = 0;

    foreach my $j (0 .. $ylen) {
        foreach my $i (0 .. $xlen) {
            my $n = $x[$i] * $y[$j] + $mem;

            if ($i == $xlen) {
                push @{$map[$j]}, $n % 10, $n / 10;
                $mem = 0;
            }
            else {
                push @{$map[$j]}, $n % 10;
                $mem = $n / 10;
            }
        }

        my $n = $ylen - $j;
        if ($n > 0) {
            push @{$map[$j]}, ((0) x $n);
        }

        my $m = $ylen - $n;
        if ($m > 0) {
            unshift @{$map[$j]}, ((0) x $m);
        }
    }

    my @result;
    my @mrange = (0 .. $#map);
    my $end    = $xlen + $ylen + 1;

    foreach my $i (0 .. $end) {
        my $n = sum(map { $map[$_][$i] } @mrange) + $mem;

        if ($i == $end) {
            push @result, $n if $n != 0;
        }
        else {
            push @result, $n % 10;
            $mem = $n / 10;
        }
    }

    return join('', reverse @result);
}

say long_multiplication('37975227936943673922808872755445627854565536638199',
                        '40094690950920881030683735292761468389214899724061');
