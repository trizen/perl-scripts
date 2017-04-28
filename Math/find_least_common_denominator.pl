#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 10 May 2016
# Website: https://github.com/trizen

# Find the least common denominator for a list of fractions and map each
# numerator to the ratio of the common denominator over the original denominator.

use 5.010;
use strict;
use warnings;

use ntheory qw(lcm);
use Math::AnyNum qw(:overload);

my @fractions = (
      19 / 6,
     160 / 51,
    1744 / 555,
     644 / 205,
    2529 / 805,
);

my $common_den = lcm(map { $_->denominator } @fractions);

my @numerators = map {
    $_->numerator * $common_den / $_->denominator
} @fractions;

say "=> Numerators:";
foreach my $n (@numerators) { say "\t$n" }

say "\n=> Common denominator: $common_den";
