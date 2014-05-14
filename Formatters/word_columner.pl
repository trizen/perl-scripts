#!/usr/bin/perl

# Author: Trizen
# Date: 29 August 2012
# Email: echo dHJpemVueEBnbWFpbC5jb20K | base64 -d
# Website: http://trizen.googlecode.com

# Put two or more lines together as columns.
# Applicable on wordlists.

use strict;
use warnings;
use encoding qw(UTF-8);

use Getopt::Std qw(getopts);

my %opt = (
           l => 2,
           s => 25,
           r => 0,
          );

getopts('l:s:rh', \%opt);

sub usage {
    die <<"USAGE";
usage: $0 [options] [files]

options:
        -l <i> : number of lines (default: $opt{l})
        -s <i> : number of spaces between words (default: $opt{s})
        -r     : reverse columns

Example: perl $0 -l 3 -s 40 file.txt > output.txt
USAGE
}

usage() if $opt{h} or not @ARGV;

foreach my $file (@ARGV) {
    open my $fh, '<:crlf:encoding(UTF-8)', $file
      or do { warn "$0: Can't open file '$file' for read: $!\n"; next };

    my @lines;
    while (<$fh>) {

        chomp;
        push @lines, $_;

        if ($. % $opt{'l'} == 0 || eof $fh and @lines) {
            my $format = ("%-$opt{s}s " x $#lines) . "%s\n";
            printf $format, $opt{r} ? reverse splice @lines : splice @lines;
        }

    }
}
