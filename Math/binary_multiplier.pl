#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 07 August 2015
# Website: https://github.com/trizen

# A very simple binary multiplier.
# Derived from: https://en.wikipedia.org/wiki/Binary_multiplier#A_more_advanced_approach:_an_unsigned_example

use 5.010;
use strict;
use warnings;

my $a = 0b11110001;
my $b = 0b11011011;

say $a;
say $b;
say $a * $b;

my @a = reverse(split(//, sprintf("%b", $a)));

my $p = 0;
foreach my $i (@a) {
    $i && ($p += $b);
    $b <<= 1;
}

say $p;
