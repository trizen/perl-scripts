#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 07 August 2015
# Website: https://github.com/trizen

# A general binary multiplier.
# Derived from: https://en.wikipedia.org/wiki/Binary_multiplier#A_more_advanced_approach:_an_unsigned_example

use 5.010;
use strict;
use integer;
use warnings;

my $a = 4253;
my $b = 7149;

my @a = reverse(split(//, sprintf("%b", $a)));
my @b = split(//, sprintf("%b", $b));

say @a;
say @b;

say $a * $b;

my @p = (0) x (@a + @b);

my $k = 0;
foreach my $i (@a) {
    if ($i) {
        say @p;
        my $carry = 0;
        foreach my $j (0 .. $#b) {
            my $add = $b[$#b - $j] + $p[$#p - $j - $k] + $carry;
            $p[$#p - $j - $k] = $add % 2;
            $carry = $add / 2;
        }
        if ($carry) {
            foreach my $j ($#b + 1 .. $#p) {
                my $add = $carry + $p[$#p - $j - $k];
                $p[$#p - $j - $k] = $add % 2;
                $carry = ($add / 2) || last;
            }
        }
    }
    ++$k;
}

say @p;
say unpack("N", pack("B32", substr("0" x 32 . join('', @p), -32)));
