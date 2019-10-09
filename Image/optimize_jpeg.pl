#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 09 October 2019
# https://github.com/trizen

# Optimize JPEG images in a given directory (recursively) using the "jpegoptim" tool.

use 5.020;
use warnings;
use File::Find qw(find);
use experimental qw(signatures);

my $batch_size = 100;    # how many files to process at once

sub optimize_jpegs ($files) {

    say ":: Optimizing a batch of ", scalar(@$files), " images...";

    system(
           "jpegoptim",
           "--preserve",    # Preserve file modification times
           @$files
          );
}

my @files;

@ARGV or die "usage: perl script.pl [dirs | files]\n";

find(
    {
     no_chdir => 1,
     wanted   => sub {
         if (/\.jpe?g\z/i and -f $_) {

             push @files, $_;

             if (@files >= $batch_size) {
                 optimize_jpegs(\@files);
                 @files = ();
             }
         }
     }
    } => @ARGV
);

if (@files) {
    optimize_jpegs(\@files);
}

say ":: Done!";
