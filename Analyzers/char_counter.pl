#!/usr/bin/perl

# Author: Trizen
# Count and list the unique characters within a file.

use strict;
use warnings;
use open IO => ':utf8', ':std';

my $file = shift @ARGV;

die "usage: $0 file\n" unless -f $file;

my %hash;
open my $fh, '<', $file;

while (defined(my $l = getc $fh)) {
    next if exists $hash{$l};
    $hash{$l} = ();
}
close $fh;

{
    local $, = ' ';
    print '-' x 80 . "\n";

    print my (@list) = (sort { lc $a cmp lc $b } keys %hash);

    print "\n" . '-' x 80 . "\n";
    print unpack('C*', join('', @list));
    print "\n" . '-' x 80 . "\n";
}

printf "\n** Unique characters used: %d\n\n", scalar keys %hash;
