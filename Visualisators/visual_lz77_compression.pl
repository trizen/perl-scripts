#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 14 May 2014
# License: GPLv3
# Website: http://github.com/trizen

# A variant of LZ77 compression, with minimum and maximum boundaries control.

use 5.010;
use strict;
use autodie;
use warnings;

use open IO => ':utf8', ':std';
use Getopt::Long qw(GetOptions);
use Term::ANSIColor qw(colored);

my $min    = 4;
my $max    = 32766;
my $buffer = 1024;

sub usage {
    my ($code) = @_;
    print <<"USAGE";
usage: $0 [options] [files]

options:
        --min=i     : minimum length of a dictionary key (default: $min)
        --max=i     : maximum length of a dictionary key (default: $max)
        --buffer=i  : buffer size of the input stream, in bytes (default: $buffer)
        --help      : print this message and exit

example: $0 --min=4 --max=32 --buffer=512 file.txt
USAGE
    exit($code // 0);
}

GetOptions(
           'buffer=i' => \$buffer,
           'min=i'    => \$min,
           'max=i'    => \$max,
           'help'     => \&usage,
          )
  or die("Error in command line arguments\n");

@ARGV || usage(1);

foreach my $file (@ARGV) {
    open my $fh, '<', $file;
    while ((my $size = read($fh, (my $block), $buffer)) > 0) {

        my %dict;
        $block =~ /(.{$min,$max}?)(?(?=.*?(\1))(?{$dict{$-[2]}{$-[0]} = length($1)}))(?!)/s;

        my $len = length($block);
        for (my $i = 0 ; $i < $len ; $i++) {
            if (exists($dict{$i})) {
                my ($key) = sort { $dict{$i}{$b} <=> $dict{$i}{$a} } keys %{$dict{$i}};
                my $vlen = $dict{$i}{$key};
                print colored("[$key,$vlen]", 'red');                  # this line prints the pointer values
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
