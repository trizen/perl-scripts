#!/usr/bin/perl

# Author: Șuteu "Trizen" Daniel
# License: GPLv3
# Date: 23th September 2013
# http://trizenx.blogspot.com

# Display all the files from a given directory with
# size greater than N and modified in or after a given date.

# usage: perl fcheck.pl [/my/dir] [MB size] [day.month.year]

use strict;
use warnings;

use File::Spec qw();
use File::Find qw(find);
use Time::Local qw(timelocal);

my $dir = @ARGV
  ? shift()                  # first argument
  : File::Spec->curdir();    # or current directory

my $min_size = @ARGV
  ? shift() * 1024**2        # second argument
  : 100 * 1024**2;           # 100MB

my $min_date = @ARGV
  ? shift()                  # third argument
  : '10.09.2013';            # 10th September 2013

# Converting date into seconds
my ($mday, $mon, $year, $hour, $min, $sec) = split(/[\s.:]+/, $min_date);
my $min_time = timelocal($sec, $min, $hour, $mday, $mon - 1, $year);

sub check_file {
    lstat;

    -f _ or return;          # ignore non-files
    -l _ and return;         # ignore links

    (-s _) > $min_size or return;           # ignore smaller files
    (stat(_))[9] >= $min_time or return;    # ignore older files

    print "$_\n";                           # we have a match
}

find {no_chdir => 1, wanted => \&check_file} => $dir;
