#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 28 July 2014
# http://trizenx.blogspot.com

# Search for a list of keywords inside a very large file

use 5.010;
use strict;
use autodie;
use warnings;

use Fcntl qw(SEEK_CUR);
use List::Util qw(max);
use Term::ANSIColor qw(colored);
use Getopt::Long qw(GetOptions);

# Input file for search
my $file = __FILE__;

# Print before and after characters
my $before = 5;
my $after  = 5;

# Buffer size
my $buffer = 1024**2;    # 1 MB

sub usage {
    my ($code) = @_;

    print <<"USAGE";

usage: $0 [options] [keywords]

options:
        --file=s        : a very large file
        --buffer=i      : buffer size (default: $buffer bytes)
        --before=i      : display this many characters before match (default: $before)
        --after=i       : display this many characters after match (default: $after)

        --help          : print this message and exit

example:
    $0 --file=document.txt "Foo Bar"

USAGE

    exit($code // 0);
}

GetOptions(
           'buffer=i' => \$buffer,
           'file=s'   => \$file,
           'before=i' => \$before,
           'after=i'  => \$after,
           'help|h'   => sub { usage(0) },
          );

@ARGV || usage(1);

my @keys = @ARGV;
my $max = max(map { length } @keys);

if ($buffer <= $max) {
    die "The buffer value can't be <= than the length of the longest keyword!\n";
}

sysopen(my $fh, $file, 0);
while ((my $size = sysread($fh, (my $chunk), $buffer)) > 0) {

    # Search for a given keyword
    foreach my $keyword (@keys) {
        my $idx = -1;
        while (($idx = index($chunk, $keyword, $idx + 1)) != -1) {

            # Take the sub-string
            my $len  = length($keyword);
            my $bar  = '-' x (40 - $len / 2);
            my $from = $idx > $before ? $idx - $before : 0;
            my $sstr = substr($chunk, $from, $len + $after + $before);

            # Split the sub-string
            my $pos = index($sstr, $keyword);
            my $bef = substr($sstr, 0,    $pos);
            my $cur = substr($sstr, $pos, $len);
            my $aft = substr($sstr, $pos + $len);

            # Highlight and print the results
            say $bar, $keyword, $bar, '-' x ($len % 2);
            say $bef, colored($cur, 'red'), $aft;
            say '-' x 80;

            {    # Unpack and print the results as character-values
                local $, = ' ';
                say unpack('C*', $bef), colored(join($,, unpack('C*', $cur)), 'red'), unpack('C*', $aft);
            }

            say '-' x 80;
        }
    }

    # Rewind back a little bit because we
    # might be in the middle of a keyword
    if ($size == $buffer) {
        sysseek($fh, sysseek($fh, 0, SEEK_CUR) - $max, 0);
    }
}
close($fh);
