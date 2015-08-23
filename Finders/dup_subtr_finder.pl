#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 11 December 2013
# http://trizenx.blogspot.com

# Find the longest duplicated sub-strings inside a string/file (based on a given minimum length).

use 5.010;
use strict;
use autodie;
use warnings;

use List::Util qw(first);
use Data::Dump qw(pp);
use Getopt::Std qw(getopts);

sub find_substrings (&@) {
    my ($code, $str, $min) = @_;

    my @substrings;
    my $len = length($str);
    my $max = int($len / 2);

    my @pos;
    for (my $i = $max ; $i >= $min ; $i--) {
        for (my $j = 0 ; $j <= $len - $i * 2 ; $j++) {

            #die $i if $i > ($len - ($j + $i));     # not gonna happen
            #say "=>> ", substr($str, $j, $i);

            if (defined(my $arr = first { $j >= $_->[0] && $j <= $_->[1] } @pos)) {
                $j = $arr->[1];
                next;
            }

            if ((my $pos = index($str, substr($str, $j, $i), $j + $i)) != -1) {
                $code->({pos => [$j, $pos], len => $i, substr => substr($str, $j, $i)});
                push @pos, [$j, $j + $i];         # don't match again in substr
                #push @pos, [$pos, $pos + $i];    # don't match again in dup-substr
                $j += $i;
            }
        }
    }

=old
    for (my $j = 0 ; $j <= $len ; $j++) {
        for (my $i = $len - $j > $max ? $max : $len - $j ; $i >= $min ; $i--) {
            next if $i > ($len - ($j + $i));
            if ((my $pos = index($str, substr($str, $j, $i), $j + $i)) != -1) {
                $code->({pos => [$j, $pos], len => $i, substr => substr($str, $j, $i)});
                $j += $i;
                last;
            }
        }
    }
=cut

    return @substrings;
}

#
## MAIN
#

sub usage {
    print <<"USAGE";
usage: $0 [options] [input-file]

options:
        -m <int>  : the minimum sub-string length

example: perl $0 -m 50 file.txt
USAGE

    exit 1;
}

my %opt;
getopts('m:', \%opt);

my $file = @ARGV && (-f $ARGV[0]) ? shift() : usage();
my $minLen = $opt{m} || (-s $file) / 10;

# Dearly spider
find_substrings { say pp(shift) } (
 do {
     local $/;
     open my $fh, '<', $file;
     <$fh>;
 },
 $minLen
                                  );
