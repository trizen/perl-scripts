#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 16 June 2014
# Website: http://github.com/trizen

# Delete files from [del dir] which does NOT exists in [cmp dir]
# NOTE: Only the base names are compared, without their extensions!

use 5.014;
use strict;
use autodie;
use warnings;

use Getopt::Std qw(getopts);
use File::Spec::Functions qw(catfile);

sub usage {
    my ($code) = @_;
    print <<"EOT";
usage: $0 [options] [cmp dir] [del dir]

options:
        -d      : delete the files
        -h      : print this message

example:
    $0 -d /my/cmp_dir /my/del_dir
EOT
    exit $code;
}

# Options
getopts('dh', \my %opt);
$opt{h} and usage(0);

# Dirs
@ARGV == 2 or usage(2);

my $cmp_dir = shift;
my $del_dir = shift;

my $rem_suffix = qr/\.\w{1,5}\z/;

# Read the [cmp dir] and store the filenames in %cmp
my %cmp;
opendir(my $cmp_h, $cmp_dir);
while (defined(my $file = readdir($cmp_h))) {
    my $abs_path = catfile($cmp_dir, $file);
    if (-f $abs_path) {
        undef $cmp{$file =~ s/$rem_suffix//r};
    }
}
closedir($cmp_h);

# Delete each file which doesn't exists in [cmp dir]
opendir(my $del_h, $del_dir);
while (defined(my $file = readdir($del_h))) {
    my $abs_path = catfile($del_dir, $file);
    if (-f $abs_path) {
        my $name = $file =~ s/$rem_suffix//r;
        if (not exists $cmp{$name}) {
            say $abs_path;
            unlink $abs_path if $opt{d};
        }
    }
}
closedir($del_h);
