#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 16 June 2014
# Website: http://github.com/trizen

# Replace unsafe characters with safe characters in filenames
# making the files portable to another FS (like FAT32)

use 5.014;
use strict;
use autodie;
use warnings;

use Getopt::Std qw(getopts);
use File::Spec::Functions qw(catfile);

sub usage {
    my ($code) = @_;

    print <<"EOT";
usage: $0 [options] [dir1] [dir2] [...]

options:
        -r      : rename the files
        -h      : print this message

example:
    $0 -r /my/dir
EOT

    exit $code;
}

# Parse arguments
getopts('rh', \my %opt);

usage(0) if $opt{h};
usage(2) if !@ARGV;

# Iterate over directories
while (defined(my $dir = shift @ARGV)) {
    opendir(my $dir_h, $dir);
    while (defined(my $file = readdir($dir_h))) {
        my $orig_name = catfile($dir, $file);
        if (-f $orig_name and $file =~ tr{:"*/?\\|}{;'+%$%%}) {
            my $new_name = catfile($dir, $file);
            say "$orig_name -> $new_name";
            rename($orig_name, $new_name) if $opt{r};
        }
    }
    closedir($dir_h);
}
