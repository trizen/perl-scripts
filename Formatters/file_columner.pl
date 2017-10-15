#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 18 August 2013
# https://github.com/trizen

# Put two or more files together as columns.

use 5.010;
use strict;
use autodie;
use warnings;

use List::Util qw(any);
use Getopt::Std qw(getopts);

binmode(\*STDOUT, ':encoding(UTF-8)');

my %opt = (s => 25);
getopts('s:h', \%opt);

sub usage {
    die <<"USAGE";
usage: $0 [options] [files]

options:
        -s <i> : number of spaces between columns (default: $opt{s})
        -h     : print this message and exit

Example: perl $0 -s 40 file1.txt file2.txt > output.txt
USAGE
}

my @files = grep {
    -f or warn "`$_' is not a file!\n";
    -f _;
} @ARGV;

if ($opt{h} || !@files) {
    usage();
}

my @fhs = map {
    open my $fh, '<:encoding(UTF-8):crlf', $_;
    $fh;
} @files;

while (any { !eof($_) } @fhs) {
    printf "%-$opt{s}s " x $#fhs . "%s\n", map {
        chomp(
              my $line =
                eof($_)
              ? q{}
              : scalar(<$_>)
             );
        $line;
    } @fhs;
}
