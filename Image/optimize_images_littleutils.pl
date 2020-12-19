#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 19 December 2020
# https://github.com/trizen

# Optimize JPEG, PNG and GIF images in a given directory (recursively) using the "opt-png", "opt-jpg" and "opt-gif" tools from littleutils.

# Littleutils:
#   https://sourceforge.net/projects/littleutils/

use 5.020;
use warnings;
use File::Find qw(find);
use experimental qw(signatures);
use File::MimeInfo::Magic qw();

my $batch_size = 100;    # how many files to process at once

sub optimize_JPEGs (@files) {

    say ":: Optimizing a batch of ", scalar(@files), " JPEG images...";

    system(
           "opt-jpg",
           "-m", "all",     # copy all extra markers
           "-t",            # preserve timestamp on modified files
           @files
          );
}

sub optimize_PNGs (@files) {

    say ":: Optimizing a batch of ", scalar(@files), " PNG images...";

    system(
           "opt-png",
           "-t",            # preserve timestamp on modified files
           @files
          );
}

sub optimize_GIFs (@files) {

    say ":: Optimizing a batch of ", scalar(@files), " GIF images...";

    system(
           "opt-gif",
           "-t",            # preserve timestamp on modified files
           @files
          );
}

my %types = (
             'image/jpeg' => {
                              files => [],
                              call  => \&optimize_JPEGs,
                             },
             'image/png' => {
                             files => [],
                             call  => \&optimize_PNGs,
                            },
             'image/gif' => {
                             files => [],
                             call  => \&optimize_GIFs,
                            },
            );

@ARGV or die "usage: perl script.pl [dirs | files]\n";

find(
    {
     no_chdir => 1,
     wanted   => sub {

         (-f $_) || return;
         my $type = File::MimeInfo::Magic::magic($_) // return;

         if (exists $types{$type}) {

             my $ref = $types{$type};
             push @{$ref->{files}}, $_;

             if (scalar(@{$ref->{files}}) >= $batch_size) {
                 $ref->{call}->(splice(@{$ref->{files}}));
             }
         }
     }
    } => @ARGV
);

foreach my $type (keys %types) {

    my $ref = $types{$type};

    if (@{$ref->{files}}) {
        $ref->{call}->(splice(@{$ref->{files}}));
    }
}

say ":: Done!";
