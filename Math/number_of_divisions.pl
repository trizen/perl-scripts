#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 05 May 2015
# http://github.com/trizen

# This program calculates the number of divisions
# needed to get the number down to five.

# The number is divided in half each time.
# Example:
#    40/2 -> 20/2 -> 10/2 -> 5      (3 divisions)

# This program is the reverse simplification of the following formulas:
#   2^n + 2^(n-2)
#   5 * 2^(n-2)

use 5.010;
use strict;
use warnings;

my $n = shift(@ARGV) // 40;           # numerator
my $d = shift(@ARGV) // 2;            # denominator
my $m = shift(@ARGV) // 5;            # the minimum value
my $y = log($n / $m) / log($d);       # the number of divisions required to get down to 5

say "To get $n down to $m, divide it by $d this many times: $y";

__END__
Example:
40 = 5 * 2^(n-2)
40/5 = 2^(n-2)
8 = 2^(n-2)
2^3 = 2^(n-2)
3 = n-2
-n = -2-3
n = 5

Closed-form:
log(40/5) / log(2) + 2

Generic:
log(n/min) / log(base)
