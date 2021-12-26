#!/usr/bin/perl

# Convert HEX to binary.

use 5.020;
use strict;
use warnings;

use Getopt::Long qw(GetOptions);

my $low_nybble = 0;

GetOptions("l|low!" => \$low_nybble)
  or die "Error in arguments";

my $hex_str = '';

while (<>) {

    # Make sure the line starts with an hexadecimal
    if (/^[[:xdigit:]]/) {

        # Collect all hexadecimal strings from the line
        while (/([[:xdigit:]]+)/g) {
            $hex_str .= $1;
        }
    }
}

binmode(STDOUT, ':raw');
print pack(($low_nybble ? "h*" : "H*"), $hex_str);
