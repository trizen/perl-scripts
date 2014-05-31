#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 21 May 2014
# License: GPLv3
# Website: http://github.com/trizen

# A visual variant of the LZ compression.

use 5.010;
use strict;
use autodie;
use warnings;

use open IO => ':utf8', ':std';
use Getopt::Long qw(GetOptions);
use Term::ANSIColor qw(colored);

my $min    = 4;
my $buffer = 1024;

sub usage {
    my ($code) = @_;
    print <<"USAGE";
usage: $0 [options] [files]

options:
        --min=i     : minimum length of a dictionary key (default: $min)
        --buffer=i  : buffer size of the input stream, in bytes (default: $buffer)
        --help      : print this message and exit

example: $0 --min=2 --buffer=512 file.txt
USAGE
    exit($code // 0);
}

GetOptions(
           'buffer=i' => \$buffer,
           'min=i'    => \$min,
           'help'     => \&usage,
          )
  or die("Error in command line arguments\n");

@ARGV || usage(1);

foreach my $file (@ARGV) {
    open my $fh, '<', $file;
    while ((my $len = read($fh, (my $block), $buffer)) > 0) {

        my %dict;
        my $limit = int($len / 2);

        foreach my $i (reverse($min .. $limit)) {
            foreach my $j (0 .. $len - $i * 2) {
                if ((my $pos = index($block, substr($block, $j, $i), $j + $i)) != -1) {
                    if (not exists $dict{$pos} or $i > $dict{$pos}[1]) {
                        $dict{$pos} = [$j, $i];
                    }
                }
            }
        }

        for (my $i = 0 ; $i < $len ; $i++) {
            if (exists($dict{$i})) {
                my ($key, $vlen) = @{$dict{$i}};
                print colored("[$key,$vlen]", 'red');    # this line prints the pointer values
                print colored(substr($block, $key, $vlen), 'blue');    # this line fetches and prints the real data
                $i += $vlen - 1;
            }
            else {
                print substr($block, $i, 1);
            }
        }
    }
    close $fh;
}
