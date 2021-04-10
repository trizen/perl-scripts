#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 23 March 2021
# https://github.com/trizen

# Convert PNG images to JPEG, using the GD library.

# The original PNG files are deleted.

use 5.020;
use warnings;
use File::Find qw(find);
use experimental qw(signatures);
use Getopt::Long qw(GetOptions);
use File::MimeInfo::Magic qw();

use GD;

GD::Image->trueColor(1);

my $batch_size = 100;    # how many files to process at once
my $quality    = 95;     # default quality value for JPEG (between 0-100)

sub convert_PNGs (@files) {

    say ":: Converting a batch of ", scalar(@files), " PNG images...";

    foreach my $file (@files) {
        say ":: Processing: $file";

        my $image = eval { GD::Image->new($file) } // do {
            warn "[!] Can't load file <<$file>>. Skipping...\n";
            next;
        };

        my $jpeg_data = $image->jpeg($quality);

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

        print {$fh} $jpeg_data;
        close $fh;

        if (-e $jpeg_file and ($orig_file ne $jpeg_file)) {
            say ":: Saved as: $jpeg_file";
            unlink($orig_file);    # remove the original PNG file
        }
    }
}

my %types = (
             'image/png' => {
                             files => [],
                             call  => \&convert_PNGs,
                            },
            );

@ARGV or die <<"USAGE";
usage: perl $0 [options] [dirs | files]

options:

    -q INT  : quality level for JPEG (default: $quality)

USAGE

GetOptions('q|quality=i' => \$quality,)
  or die "Error in command-line arguments!";

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
