#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 04 November 2012
# https://github.com/trizen

# Update files in a directory, with files from other dirs.
# Example: perl file_updater.pl -o /tmp /root
# /tmp/dir/file.txt is updated with /root/dir/file.txt
# if the file from the /root dir is newer than the file from the /tmp dir.

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

my @dirs;
foreach my $dir (@ARGV) {
    if (not -d -r $dir) {
        warn "[!] Invalid dir '$dir': $!\n";
        next;
    }
    push @dirs, rel2abs($dir);
}

sub update_files {

    return if $_ eq $output_dir;
    return unless -f;

    my $filename = substr($_, length($output_dir) + 1);
    my $mdays = -M _;

    foreach my $dir (@dirs) {
        my $file = catfile($dir, $filename);
        if (-e $file and -M (_) < $mdays and compare($file, $_) == 1) {
            say "Updating: $file -> $_";
            copy($file, $_) or do { warn "[!] Copy failed: $!\n" };
        }
    }
}

find {
      no_chdir => 1,
      wanted   => \&update_files,
     } => $output_dir;
