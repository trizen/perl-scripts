#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 09 October 2019
# https://github.com/trizen

# Optimize JPEG and PNG images in a given directory (recursively) using the "jpegoptim" and "optipng" tools.

use 5.036;
use File::Find   qw(find);
use Getopt::Long qw(GetOptions);

my $batch_size   = 100;    # how many files to process at once
my $use_exiftool = 0;      # true to use `exiftool` instead of `File::MimeInfo::Magic`

sub optimize_JPEGs (@files) {

    say ":: Optimizing a batch of ", scalar(@files), " JPEG images...";

    system(
        "jpegoptim",
        "--preserve",    # preserve file modification times
        ##'--max=90',
        ##'--size=2048',
        '--all-progressive',
        @files
          );
}

sub optimize_PNGs (@files) {

    say ":: Optimizing a batch of ", scalar(@files), " PNG images...";

    system(
        "optipng",
        "-preserve",    # preserve file attributes if possible
        "-o1",          # optimization level
        @files
          );
}

sub determine_mime_type ($file) {

    if ($use_exiftool) {
        my $res = `exiftool \Q$file\E`;
        $? == 0       or return;
        defined($res) or return;
        if ($res =~ m{^MIME\s+Type\s*:\s*(\S+)}mi) {
            return $1;
        }
        return;
    }

    require File::MimeInfo::Magic;
    File::MimeInfo::Magic::magic($file);
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
            );

GetOptions('exiftool!'    => \$use_exiftool,
           'batch-size=i' => \$batch_size,)
  or die "Error in command-line arguments!";

@ARGV or die <<"USAGE";
usage: perl $0 [options] [dirs | files]

options:

    --batch=i  : how many files to process at once (default: $batch_size)
    --exiftool : use `exiftool` to determine the MIME type (default: $use_exiftool)

USAGE

find(
    {
     no_chdir => 1,
     wanted   => sub {

         (-f $_) || return;
         my $type = determine_mime_type($_) // return;

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
