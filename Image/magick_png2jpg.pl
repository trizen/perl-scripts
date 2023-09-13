#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 23 March 2021
# https://github.com/trizen

# Convert PNG images to JPEG, using the ImageMagick library.

# The original PNG files are deleted.

use 5.036;
use File::Find    qw(find);
use Image::Magick qw();
use Getopt::Long  qw(GetOptions);

my $batch_size   = 100;    # how many files to process at once
my $use_exiftool = 0;      # true to use `exiftool` instead of `File::MimeInfo::Magic`

sub convert_PNGs (@files) {

    say ":: Converting a batch of ", scalar(@files), " PNG images...";

    foreach my $file (@files) {
        say ":: Processing: $file";

        my $image = Image::Magick->new;

        $image->Read(filename => $file) && do {
            warn "[!] Can't load file <<$file>>. Skipping...\n";
            next;
        };

        my $orig_file = $file;
        my $jpeg_file = $file;

        if ($jpeg_file =~ s/\.png\z/.jpg/i) {
            ## ok
        }
        else {
            $jpeg_file .= '.jpg';
        }

        if (-e $jpeg_file) {
            warn "[!] File <<$jpeg_file>> already exists...\n";
            next;
        }

        open(my $fh, '>:raw', $jpeg_file) or do {
            warn "[!] Can't open file <<$jpeg_file>> for writing: $!\n";
            next;
        };

        $image->Write(file => $fh, filename => $jpeg_file);

        close $fh;

        if (-e $jpeg_file and ($orig_file ne $jpeg_file)) {
            say ":: Saved as: $jpeg_file";
            unlink($orig_file);    # remove the original PNG file
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
             'image/png' => {
                             files => [],
                             call  => \&convert_PNGs,
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
