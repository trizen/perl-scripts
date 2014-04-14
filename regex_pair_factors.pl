#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 14 April 2014
# Website: http://github.com/trizen

# Get the pair factors for a number (using a regex)

my $prod = 36;
my $half = $prod / 2;
my $msg  = 'a' x $prod;

for my $i (1 .. $half) {
    for my $j ($i .. $half) {
        if ($msg =~ /^(?>a{$i}){$j}\z/) {
            print "$j * $i == $prod\n";
        }
    }
}
