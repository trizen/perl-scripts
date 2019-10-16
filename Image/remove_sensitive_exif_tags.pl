#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 09 October 2019
# https://github.com/trizen

# Remove sensitive EXIF information from images that may be used for online-tracking.

# The script uses the "exiftool".
#   https://www.sno.phy.queensu.ca/~phil/exiftool/

# This is particularly necessary for photos downloaded from Facebook, which include a tracking ID inside them.
#   https://news.ycombinator.com/item?id=20427007
#   https://dustri.org/b/on-facebooks-pictures-watermarking.html
#   https://www.hackerfactor.com/blog/index.php?/archives/726-Facebook-Tracking.html
#   https://www.reddit.com/r/privacy/comments/ccndcq/facebook_is_embedding_tracking_data_inside_the/

use 5.020;
use warnings;
use File::Find qw(find);

use Getopt::Std qw(getopts);
use experimental qw(signatures);

my %opts;
getopts('-e', \%opts);    # flag "-e" removes extra tags

my $extra      = $opts{e} || 0;          # true to remove additional information, such as the camera name
my $batch_size = 100;                    # how many files to process at once
my $image_re   = qr/\.(png|jpe?g)\z/i;

sub strip_tags ($files) {

    say ":: Stripping tracking tags of ", scalar(@$files), " photos...";
    say ":: The first image is: $files->[0]";

    system(
        "exiftool",

        "-overwrite_original_in_place",    # overwrite image in place

        "-*Serial*Number*=",               # remove serial number of camera photo
        "-*ImageUniqueID*=",               # remove the unique image ID
        "-*Copyright*=",                   # remove copyright data
        "-usercomment=",                   # remove any user comment
        "-iptc=",                          # remove any IPTC data
        "-xmp=",                           # remove any XMP data
        "-geotag=",                        # remove geotag data
        "-gps:all=",                       # remove ALL GPS data

        (
         $extra
         ? (
            "-make=",                      # remove the brand name of the camera used to make the photo
            "-model=",                     # remove the model name of the camera used to make the photo
            "-software=",                  # remove the software name used to edit/process the photo
            "-imagedescription=",          # remove any image description
           )
         : ()
        ),

        @$files
          );
}

my @files;

@ARGV or die "usage: perl script.pl [-e] [dirs | files]\n";

find(
    {
     no_chdir => 1,
     wanted   => sub {
         if (/$image_re/ and -f $_) {

             push @files, $_;

             if (@files >= $batch_size) {
                 strip_tags(\@files);
                 @files = ();
             }
         }
     }
    } => @ARGV
);

if (@files) {
    strip_tags(\@files);
}

say ":: Done!";
