#!/usr/bin/perl

# Code from "Mastering Algorithms with Perl" book
# derived from code by Nathan Torkington

# Code improved by Daniel "Trizen" Șuteu
# Added support for very large files and locale support

# Date: 29th November 2013
# http://trizenx.blogspot.com

use 5.010;
use strict;
use autodie;
use warnings;

# Use locale when '-l' switch is specified
use if $#ARGV >= 0 && $ARGV[0] eq '-l' => 'locale';

# Using Math::BigInt to work with very large files
use Math::BigInt try => 'GMP,Pari';

# For parsing the command line switches
use Getopt::Std qw(getopts);

my %opts;
getopts('lh', \%opts);

sub usage {
    my ($code) = @_;

    print <<"USAGE";
usage: $0 [options] <line> <file>

options:
        -l  : use the current locale for string comparisons

example:
        perl $0 -l "hello world" bigList.txt
USAGE

    exit $code;
}

usage(0)  if $opts{h};
usage(-1) if $#ARGV != 1;

my ($word, $file) = @ARGV;

open(my $fh, '<', $file);
my $position = binary_search_file($fh, $word);

if   (defined $position) { print "$word occurs at position $position\n" }
else                     { print "$word does not occur in $file.\n" }

sub binary_search_file {
    my ($file, $word) = @_;

    my $low  = Math::BigInt->new(0);           # Guaranteed to be the start of a line.
    my $high = Math::BigInt->new(-s $file);    # Might not be the start of a line.

    my $line;
    while ($high != $low) {

        my $mid = ($high + $low) / 2;
        seek($file, $mid, 0);

        # $mid is probably in the middle of a line, so read the rest
        # and set $mid2 to that new position.
        scalar <$file>;
        my $mid2 = Math::BigInt->new(tell($file));

        if ($mid2 < $high) {    # We're not near file's end, so read on.
            $mid  = $mid2;
            $line = <$file>;
        }
        else {                  # $mid plunked us in the last line, so linear search.
            seek($file, $low, 0);
            while (defined($line = <$file>)) {
                last if compare($line, $word) >= 0;
                $low = Math::BigInt->new(tell($file));
            }
            last;
        }

        compare($line, $word) == -1
          ? ($low = $mid)
          : ($high = $mid);
    }

    compare($line, $word) == 0
      ? $low
      : ();
}

sub compare {
    my ($word1, $word2) = @_;

    chomp $word1;
    $word1 cmp $word2;
}
