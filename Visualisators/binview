#!/usr/bin/perl

# Author: Trizen
# License: GPLv3
# Date: 09 October 2013
# http://trizenx.blogspot.com

# Prints bits and bytes (or byte values) from a binary file.

use 5.010;
use strict;
use autodie;
use warnings;

sub usage {
    print STDERR "usage: $0 file [cols]\n";
    exit 1;
}

my $file = shift() // usage();
my $cols = shift() // 1;

sysopen my $fh, $file, 0;
while (sysread($fh, (my $chars), $cols) > 0) {
    foreach (split //, $chars) {
        printf "%10s%4s", unpack("B*"), /[[:print:]]/ ? $_ : sprintf("%03d", ord);
    }
    print "\n";
}
close $fh;
