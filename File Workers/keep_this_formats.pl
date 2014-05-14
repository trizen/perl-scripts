#!/usr/bin/perl

# Author: Trizen
# License: GPLv3
# Date: 12 September 2012
# http://trizen.googlecode.com

# Keep only one or more type of file formats in a directory and it's subdirectories.
# List and remove the other formats.

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
        -r           : remove the other formats (default: list them)
        -v           : verbose mode

example: $0 -v -f 'mp3,ogg,wma' /home/Music
USAGE
}

my %opts;
getopts('f:rv', \%opts);

$opts{f} // usage();
@ARGV || usage();

my @formats = map qr{\.\Q$_\E\z}i, split /\s*,\s*/, $opts{f};

find {
    wanted => sub {
        if (not $_ ~~ \@formats and -f) {
            say if $opts{v};
            if ($opts{r}) {
                unlink($_) or warn "Can't remove file '$_': $!";
            }
        }
    },
    no_chdir => 1,
     } => @ARGV;
