#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 25 April 2014
# Website: http://github.com/trizen

# Print only the lines that repeat n times in one or more files.
# usage: perl n_repeated_lines.pl [n] [file1.txt] [...]

use strict;
use warnings;

my $n = @ARGV && not(-f $ARGV[0]) ? shift() : 2;

my %seen;
while (<>) {
    /\S/ || next;
    ++$seen{unpack('A*')} == $n && print;
}
