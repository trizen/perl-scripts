#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 04 November 2012
# https://github.com/trizen

# Update files in a directory, with files from other dirs.
# Example: perl dir_file_updater.pl -o /tmp /root
# /tmp/file.txt is updated with the newest file from the /root dir,
# or it's sub-directories, called file.txt, but only if the file is newer
# than the file from the /tmp dir. This script updates only the files from
# the OUTPUT_DIR, without checking it's sub-directories.

use 5.010;
use strict;
use warnings;

use File::Copy qw(copy);
use File::Find qw(find);
use Getopt::Std qw(getopts);
use File::Compare qw(compare);
use File::Spec::Functions qw(rel2abs catfile);

my %opts;
getopts('o:', \%opts);

sub usage {
    die <<"EOH";
usage: $0 [options] [dirs]

options:
        -o <output_dir>  : update files in this directory

example: $0 -o /my/path/out /my/path/input
EOH
}

my $output_dir = $opts{o};

if (   not defined $output_dir
    or not -d $output_dir
    or not @ARGV) {
    usage();
}

$output_dir = rel2abs($output_dir);

my %table;

sub update_files {
    my $file = $File::Find::name;
    return unless -f $file;

    if (not exists $table{$_} or -M ($table{$_}) > -M ($file)) {
        $table{$_} = $file;
    }
}

my @dirs;
foreach my $dir (@ARGV) {
    if (not -d -r $dir) {
        warn "[!] Invalid dir '$dir': $!\n";
        next;
    }
    push @dirs, rel2abs($dir);
}

find {wanted => \&update_files,} => @dirs;

opendir(my $dir_h, $output_dir)
  or die "Can't read dir '$output_dir': $!\n";

while (defined(my $file = readdir($dir_h))) {
    next if $file eq q{.} or $file eq q{..};
    my $filename = catfile($output_dir, $file);
    next unless -f $filename;

    if (exists $table{$file}) {
        if (-M ($table{$file}) < -M ($filename)
            and compare($table{$file}, $filename) != 0) {
            say "Updating: $table{$file} -> $filename";
            copy($table{$file}, $filename) or do { warn "[!] Copy failed: $!\n" };
        }
    }
}

closedir $dir_h;
