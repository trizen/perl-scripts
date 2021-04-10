#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 10 April 2021
# https://github.com/trizen

# Convert WEBP images to PNG, using the `dwebp` tool from "libwebp".

# The original WEBP files are deleted.

use 5.020;
use warnings;
use File::Find qw(find);
use experimental qw(signatures);
use File::MimeInfo::Magic qw();

my $batch_size = 100;                 # how many files to process at once
my $dwebp_cmd  = "/usr/bin/dwebp";    # `dwebp` command

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

my %types = (
             'image/webp' => {
                              files => [],
                              call  => \&convert_WEBPs,
                             },
            );

@ARGV or die <<"USAGE";
usage: perl $0 [dirs | files]
USAGE

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
