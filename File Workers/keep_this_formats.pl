#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 12 September 2012
# Edit: 11 August 2017
# https://github.com/trizen

# Keep only one or more type of file formats in a directory and its sub-directories.
# List and remove the other formats (when -r is specified).

use 5.010;
use strict;
use warnings;

use File::Find qw(find);
use Getopt::Std qw(getopts);

sub usage {
    die <<"USAGE";
usage: $0 [options] <dirs>

options:
        -f <formats> : the list of formats (comma separated)
        -r           : remove the other formats (default: off)

example: $0 -f 'mp3,ogg,wma' /home/Music
USAGE
}

my %opts;
getopts('f:r', \%opts);

$opts{f} // usage();
@ARGV || usage();

my $formats_re = do {
    local $" = '|';
    my @a = map { quotemeta } split(/\s*,\s*/, $opts{f});
    qr/\.(?:@a)\z/i;
};

find {
    wanted => sub {
        if (not /$formats_re/ and -f) {
            say $_;
            if ($opts{r}) {
                unlink($_) or warn "Can't remove file '$_': $!";
            }
        }
    },
    no_chdir => 1,
} => @ARGV;
