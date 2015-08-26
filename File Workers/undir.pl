#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 10th August 2014
# Website: https://github.com/trizen

# Move all the files from a directory's sub-directories into the main directory (with depth control)

use 5.010;
use strict;
use warnings;

use Getopt::Std qw(getopts);

use File::Copy qw(move);
use File::Find qw(find);
use File::Basename qw(basename);
use File::Spec::Functions qw(catfile splitdir);

sub usage {
    my ($code) = @_;

    print <<"USAGE";
usage: $0 [options] [dirs]

options:
        -u     : undir the files
        -d     : delete empty directories
        -t int : depth limit (default: unlimited)

example:
     $0 -u -t 2 /my/dir
USAGE

    exit($code // 0);
}

getopts('udht:', \my %opt);
$opt{h} && usage(0);

my @dirs = grep { -d } @ARGV;
@dirs || usage(2);

foreach my $dir (@dirs) {

    my $depth = splitdir($dir);

    my %dirs;
    my @files;
    find(
        {
         no_chdir => 1,
         wanted   => sub {
             return if $File::Find::dir eq $dir;
             if (defined $opt{t}) {
                 return if (splitdir($File::Find::dir) - $depth > $opt{t});
             }
             $dirs{$File::Find::dir} //= 1;
             push @files, $_ if -f;
           }
        } => $dir
    );

    my $error = 0;
    foreach my $file (@files) {
        say $file;
        if ($opt{u}) {
            my $basename = basename($file);
            my $newfile = catfile($dir, $basename);
            if (-e $newfile) {
                warn "File `$basename' already exists in dir `$dir'...";
                ++$error;
            }
            else {
                move($file, $newfile) || do {
                    warn "Can't move file `$file' to `$newfile': $!";
                    ++$error;
                };
            }
        }
    }

    if ($error == 0) {
        foreach my $key (keys %dirs) {
            rmdir($key);
        }
    }
}
