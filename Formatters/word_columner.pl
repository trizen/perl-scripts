#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 29 August 2012
# Edit: 18 January 2015
# Website: https://github.com/trizen

# Put two or more lines together as columns. (with unicode char width support)

use strict;
use warnings;
use open IO => ':encoding(UTF-8)', ':std';

use Getopt::Std qw(getopts);

my %opt = (
           c => 2,
           s => 25,
           l => 0,
           r => 0,
           u => 0,
          );

getopts('c:s:l:ruh', \%opt);

sub usage {
    die <<"USAGE";
usage: $0 [options] [files]

options:
        -c <i> : number of columns (default: $opt{c})
        -s <i> : number of spaces between words (default: $opt{s})
        -l <i> : number of leading spaces (default: $opt{l})
        -u     : use the unicode char width feature
        -r     : reverse columns

Example: perl $0 -l 3 -s 40 file.txt > output.txt
USAGE
}

usage() if $opt{h} or not @ARGV;

foreach my $file (@ARGV) {
    open my $fh, '<', $file
      or do { warn "$0: Can't open file '$file' for read: $!\n"; next };

    my @lines;
    while (<$fh>) {

        chomp;
        push @lines, $_;

        if ($. % $opt{c} == 0 || eof $fh and @lines) {
            my @cols = $opt{r} ? reverse splice @lines : splice @lines;

            my $format = ' ' x $opt{l};
            if ($opt{u}) {
                require Text::CharWidth;
                foreach my $i (0 .. $#cols - 1) {
                    my $diff = abs(Text::CharWidth::mbswidth($cols[$i]) - length($cols[$i]));
                    $format .= "%-" . ($opt{s} - $diff) . 's';
                }
            }
            else {
                $format = "%-$opt{s}s " x $#cols;
            }
            $format .= "%s\n";

            printf $format, @cols;
        }
    }
}
