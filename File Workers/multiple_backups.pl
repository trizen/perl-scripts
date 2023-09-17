#!/usr/bin/perl

# Author: Trizen
# Date: 11 September 2023
# https://github.com/trizen

# Create multiple backups of a list of filenames and update them as necessary.

use 5.036;
use Getopt::Long;
use File::Basename        qw(basename);
use File::Copy            qw(copy);
use File::Spec::Functions qw(catfile curdir);

my $backup_dir = curdir();

sub usage ($exit_code = 0) {
    print <<"EOT";
usage: $0 [options] [filenames]

options:
    --dir=s : directory where to save the backups (default: $backup_dir)
EOT
    exit($exit_code);
}

GetOptions("d|dir=s" => \$backup_dir,
           'h|help'  => sub { usage(0) },)
  or die("Error in command line arguments\n");

my %timestamps = (
                  "1h"  => 1 / 24,
                  "1d"  => 1,
                  "3d"  => 3,
                  "30d" => 30,
                  "1y"  => 365,
                 );

@ARGV || usage(2);

foreach my $file (@ARGV) {
    say ":: Processing: $file";
    foreach my $key (sort keys %timestamps) {
        my $checkpoint_time = $timestamps{$key};
        my $backup_file     = catfile($backup_dir, basename($file) . '.' . $key);
        if (not -e $backup_file or ((-M $backup_file) >= $checkpoint_time)) {
            say "   > writing backup: $backup_file";
            copy($file, $backup_file)
              or warn "Can't copy <<$file>> to <<$backup_file>>: $!";
        }
    }
}
