#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 14 April 2014
# Website: http://github.com/trizen

# Get the pair factors for a number (using a regex)

use 5.010;
use strict;
use warnings;

my $prod = $ARGV[0] // 36;
my $msg  = 'a' x $prod;

for my $i (2 .. $prod / 2) {
    for my $j ($i .. $prod / $i) {
        if ($msg =~ /^(?:a{$i}){$j}\z/) {
            say "$j * $i == $prod";
        }
    }
}
