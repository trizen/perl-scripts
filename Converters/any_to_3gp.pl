#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 10 June 2013
# https://github.com/trizen

#
## Convert any media file to the 3gp mobile format.
#

# Requires ffmpeg compiled with '--enable-libopencore_amrnb'

use 5.010;
use strict;
use warnings;

use Getopt::Std qw(getopts);
use File::Path qw(make_path);
use File::Spec::Functions qw(catfile);

my %opt;
getopts('f:o:i:h', \%opt);

if ($opt{h} or not defined $opt{f}) {
    print <<"USAGE";
usage: $0 [options]

options:
        -f format       : convert only this video formats (can be a regex)
        -i input dir    : convert videos from this directory (default: '.')
        -o output dir   : where to put the converted videos (default: '.')

example: perl $0 -f 'mp4|webm'  -i Videos/  -o 3GP_Videos/
USAGE

    exit !$opt{h};
}

my $output_dir = $opt{o} // '.';
my $input_dir  = $opt{i} // '.';
my $input_format = eval { qr{\.\K(?:$opt{f})\z}i } // die "$0: Invalid regex: $@";

if (not -d $output_dir) {
    make_path($output_dir)
      or die "$0: Can't create path '$output_dir': $!\n";
}

opendir(my $dir_h, $input_dir)
  or die "$0: Can't open dir '$input_dir': $!\n";

while (defined(my $file = readdir $dir_h)) {

    (my $output_file = $file) =~ s{$input_format}{3gp} or next;
    -f -s (my $input_file = catfile($input_dir, $file)) or next;

    system qw(ffmpeg -i), $input_file, qw(
      -acodec    amr_nb
      -ar          8000
      -ac             1
      -ab            32
      -vcodec      h263
      -s           qcif
      -r             15
      ), catfile($output_dir, $output_file);

    if ($? != 0) {
        die "$0: ffmpeg exited with a non-zero code!\n";
    }
}

closedir($dir_h);
