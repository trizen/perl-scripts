#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 09 October 2019
# https://github.com/trizen

# Optimize JPEG and PNG images in a given directory (recursively) using the "jpegoptim" and "optipng" tools.

use 5.020;
use warnings;
use File::Find qw(find);
use experimental qw(signatures);

my $batch_size = 100;    # how many files to process at once

sub optimize_JPEGs ($files) {

    say ":: Optimizing a batch of ", scalar(@$files), " JPEG images...";

    system(
           "jpegoptim",
           "--preserve",    # preserve file modification times
           @$files
          );
}

sub optimize_PNGs ($files) {

    say ":: Optimizing a batch of ", scalar(@$files), " PNG images...";

    system(
           "optipng",
           "-preserve",     # preserve file attributes if possible
           "-o1",           # optimization level
           @$files
          );
}

my @PNGs;
my @JPEGs;

@ARGV or die "usage: perl script.pl [dirs | files]\n";

find(
    {
     no_chdir => 1,
     wanted   => sub {
         if (/\.jpe?g\z/i and -f $_) {

             push @JPEGs, $_;

             if (@JPEGs >= $batch_size) {
                 optimize_JPEGs(\@JPEGs);
                 @JPEGs = ();
             }
         }
         elsif (/\.png\z/i and -f $_) {

             push @PNGs, $_;

             if (@PNGs >= $batch_size) {
                 optimize_PNGs(\@PNGs);
                 @PNGs = ();
             }
         }
     }
    } => @ARGV
);

if (@JPEGs) {
    optimize_JPEGs(\@JPEGs);
}

if (@PNGs) {
    optimize_PNGs(\@PNGs);
}

say ":: Done!";
