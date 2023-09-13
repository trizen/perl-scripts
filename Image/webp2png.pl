#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 10 April 2021
# https://github.com/trizen

# Convert WEBP images to PNG, using the `dwebp` tool from "libwebp".

# The original WEBP files are deleted.

use 5.036;
use File::Find   qw(find);
use Getopt::Long qw(GetOptions);

my $batch_size   = 100;                 # how many files to process at once
my $dwebp_cmd    = "/usr/bin/dwebp";    # `dwebp` command
my $use_exiftool = 0;                   # true to use `exiftool` instead of `File::MimeInfo::Magic`

(-x $dwebp_cmd)
  or die "Error: `dwebp` tool from 'libwebp' is not installed!\n";

sub convert_WEBPs (@files) {

    say ":: Converting a batch of ", scalar(@files), " WEBP images...";

    foreach my $file (@files) {

        my $orig_file = $file;
        my $png_file  = $file;

        if ($png_file =~ s/\.webp\z/.png/i) {
            ## ok
        }
        else {
            $png_file .= '.png';
        }

        if (-e $png_file) {
            warn "[!] File <<$png_file>> already exists...\n";
            next;
        }

        system($dwebp_cmd, $orig_file, '-o', $png_file);

        if ($? == 0 and (-e $png_file) and ($png_file ne $orig_file)) {
            unlink($orig_file);
        }
    }
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
             'image/webp' => {
                              files => [],
                              call  => \&convert_WEBPs,
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
