#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 23 August 2015
# Website: https://github.com/trizen

# Sort and move a list of file names into a given directory

use 5.016;
use strict;
use warnings;

use open IO => ':utf8', ':std';

use File::Copy qw(move);
use File::Basename qw(basename);
use File::Spec::Functions qw(catfile);
use Getopt::Long qw(GetOptions);

my $reverse = 0;         # bool
my $sort_by = 'none';    # string
my $output_dir;          # string
my $move = 'none';       # string

my %sorts = (
             none   => sub { },
             name   => sub { $a cmp $b },
             iname  => sub { fc($a) cmp fc($b) },
             length => sub { length($a) <=> length($b) },
             size   => sub { (-s $a) <=> (-s $b) },
             atime  => sub { (stat($a))[8] <=> (stat($b))[8] },
             mtime  => sub { (stat($a))[9] <=> (stat($b))[9] },
             ctime  => sub { (stat($a))[10] <=> (stat($b))[10] },
            );

sub help {
    print <<"EOT";
usage: $0 [options] < [input.txt]

options:
    -s  --sort-by=s     : sort the files by:
                            name   -> sort by filename
                            iname  -> sort by filename case-insensitively
                            length -> sort by the length of the filename
                            size   -> sort by the size of the file
                            atime  -> sort by file access time
                            mtime  -> sort by file modification time
                            ctime  -> sort by file inode change time
                            none   -> don't do any sorting (default)

    -r  --reverse!      : reverse the sorting
    -o  --out-dir=s     : move the files into this directory
    -m  --move=s        : move the files as follows:
                            first  -> moves the first n-1 files
                            last   -> moves the last n-1 files
                            all    -> moves all files
                            none   -> don't move any file (default)

example:
    $0 --sort-by=mtime --move=last --out-dir=/tmp < files.txt
EOT
    exit 0;
}

GetOptions(
           'm|move=s'           => \$move,
           'r|reverse!'         => \$reverse,
           'o|out-dir=s'        => \$output_dir,
           's|sort-by|sortby=s' => \$sort_by,
           'h|help'             => \&help,
          )
  or die("error in command line arguments");

my $sort_code = $sorts{lc($sort_by)} // die "Invalid value `$sort_by' for option `--sort-by'";

if ($move ne 'none') {
    if (defined($output_dir)) {
        if (not -d $output_dir) {
            die "Invalid value `$output_dir' for option `--out-dir' (requires an existent directory)";
        }
    }
    else {
        die "Please add the `--out-dir' option, in order to `--move` files";
    }
}

sub process_files {
    my (@files) = @_;

    @files = do {
        my %seen;
        grep { !$seen{$_}++ } @files;
    };

    if ($sort_by ne 'none') {
        @files = sort $sort_code @files;
    }

    if ($reverse) {
        @files = reverse(@files);
    }

    my @all_files = @files;

    if ($move eq 'none') {
        @files = ();
    }
    elsif ($move eq 'first') {
        @files = @files[0 .. $#files - 1];
    }
    elsif ($move eq 'last') {
        @files = @files[1 .. $#files];
    }
    elsif ($move eq 'all') {
        ## ok
    }
    else {
        die "Invalid value `$move' for `--move`";
    }

    my %table;
    @table{@files} = ();

    foreach my $file (@all_files) {
        print $file;
        if (exists $table{$file}) {
            my $basename = basename($file);
            my $dest = catfile($output_dir, $basename);

            print " -> $dest";

            if (-e $dest) {
                print " (error: already exists)";
            }
            else {
                if (move($file, $dest)) {
                    print " (OK)";
                }
                else {
                    print " (error: $!)";
                }
            }
        }
        print "\n";
    }

    if (@all_files) {
        say "-" x 80;
    }
}

my @files;
while (defined(my $line = <>)) {
    chomp($line);

    if (-e $line) {
        push @files, $line;
    }
    elsif (@files) {
        process_files(@files);
        @files = ();
    }
}

process_files(@files) if @files;
