#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13 November 2016
# https://github.com/trizen

# One-time pad symmetric encryption, where the key is pseudo-randomly generated from a given seed.

# See also:
#   https://en.wikipedia.org/wiki/One-time_pad

#---------------------------------------------------
#                !!! WARNING !!!
#---------------------------------------------------
# This program is just a proof-of-concept.
# Do NOT use this program to encrypt sensitive data!
#---------------------------------------------------

use 5.010;
use strict;
use warnings;

use Getopt::Std qw(getopts);

my %opts;
getopts('s:h', \%opts);

use constant {
              READ_SIZE => 2 * 1024**2,    # 2 MB
             };

sub usage {
    warn "\n[ERROR]: ", @_, "\n\n" if @_;
    print <<"USAGE";
usage: $0 [options] [<input] [>output]

options:
        -s SEED   : random seed

example:
    $0 -s 42 < input.txt > output.dat

USAGE
    exit 1;
}

$opts{h} && usage();

encode_file(
            in_fh  => \*STDIN,
            out_fh => \*STDOUT,
            seed   => defined($opts{s}) ? $opts{s} : usage("No seed specified!"),
           );

sub generate_key {
    my ($length) = @_;
    pack('C*', map { int(rand(256)) } 1 .. $length);
}

sub encode_file {
    my %args = @_;

    srand($args{seed});

    while (1) {
        my $len = read($args{in_fh}, my ($chunk), READ_SIZE);
        my $key = generate_key($len);

        print {$args{out_fh}} $chunk ^ $key;
        last if $len != READ_SIZE;
    }

    return 1;
}
