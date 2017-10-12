#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 12 October 2017
# https://github.com/trizen

# Compare two paths file-by-file and diplay the filenames of (non-)duplicate files.

use 5.010;
use strict;
use warnings;

use Cwd qw(abs_path);
use File::Find qw(find);
use File::Compare qw(compare);
use Getopt::Long qw(GetOptions);
use File::Spec::Functions qw(catdir catfile catpath splitdir splitpath);

my $show_duplicates = 0;

sub usage {
    print <<"EOT";
usage: $0 [options] [dir1] [dir2]

options:
    -e --equal : display filenames of duplicate files (default: $show_duplicates)

EOT
    exit;
}

GetOptions('e|equal!' => \$show_duplicates,
           'h|help'   => \&usage,)
  or die("Error in command line arguments!");

my ($dir1, $dir2) = map { abs_path($_) } grep { -d } @ARGV;

if (not defined($dir1) or not defined($dir2)) {
    die "usage: $0 [dir1] [dir2]\n";
}

my ($dir1_volume, $dir1_path) = splitpath($dir1, 1);
my ($dir2_volume, $dir2_path) = splitpath($dir2, 1);

my @dir1_parts = splitdir($dir1_path);
my @dir2_parts = splitdir($dir2_path);

find {
    no_chdir => 1,
    wanted   => sub {
        (-f $_) || return;

        my $file1 = $_;
        my (undef, $directory, $file) = splitpath($file1);

        my @parts = splitdir($directory);
        splice(@parts, 0, scalar(@dir1_parts));

        my $file2 = catpath($dir2_volume, catdir(@dir2_parts, @parts), $file);

        (-f $file2) || return;

        my $are_equal = ((-s $file1) == (-s $file2) and compare($file1, $file2) == 0);

        if ($show_duplicates) {
            say catfile(@parts, $file) if $are_equal;
        }
        else {
            say catfile(@parts, $file) if !$are_equal;
        }
    }
} => $dir1;
