#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 18 August 2015
# Website: https://github.com/trizen
# Calculate the product of first n primes
# See: https://en.wikipedia.org/wiki/Primorial

# usage: perl primorial.pl [n]

use 5.010;
use strict;
use warnings;

use ntheory qw(pn_primorial);

say pn_primorial(shift(@ARGV) // 5);
