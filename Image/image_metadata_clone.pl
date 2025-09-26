#!/usr/bin/perl

# Author: Trizen
# Date: 26 September 2025
# https://github.com/trizen

# Copy EXIF metadata from images, given a source directory and a destination directory.

# Metadata from each image from the source directory is added to the images
# in the destination directory, based on the filename of each image.

use 5.036;
use Image::ExifTool qw();
use File::Find      qw(find);
use File::Basename  qw(basename);
use Getopt::Long    qw(GetOptions);

my $img_formats = '';

my @img_formats = qw(
  jpeg
  jpg
);

sub usage($exit_code = 0) {

    print <<"EOT";
usage: $0 [options] [source dir] [dest dir]

options:
    -f  --formats=s,s   : specify more image formats (default: @img_formats)
    --help              : print this message and exit
EOT

    exit $exit_code;
}

GetOptions("f|formats=s" => \$img_formats,
           'help'        => sub { usage(0) })
  or die("Error in command line arguments\n");

@ARGV == 2 or usage(1);

sub add_exif_info($source_image, $dest_image) {

    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat($dest_image);

    my $exifTool  = Image::ExifTool->new;
    my $exif_info = $exifTool->SetNewValuesFromFile($source_image);

    $exifTool = Image::ExifTool->new;

    foreach my $key (keys %$exif_info) {
        my $value = $exif_info->{$key};
        $exifTool->SetNewValue($key, $value);
    }

    $exifTool->WriteInfo($dest_image);

    # Set the original modification time
    utime($atime, $mtime, $dest_image)
      or warn "Can't change timestamp: $!\n";

    # Set original permissions
    chmod($mode & 07777, $dest_image)
      or warn "Can't change permissions: $!\n";

    # Set the original ownership of the image
    chown($uid, $gid, $dest_image);
}

push @img_formats, map { quotemeta } split(/\s*,\s*/, $img_formats);

my $img_formats_re = do {
    local $" = '|';
    qr/\.(@img_formats)\z/i;
};

my ($source_dir, $dest_dir) = @ARGV;

my %source_files;

find {
    no_chdir => 1,
    wanted   => sub {
        (/$img_formats_re/o && -f) || return;
        my $basename = basename($_);
        $source_files{$basename} = $_;
    }
} => $source_dir;

find {
    no_chdir => 1,
    wanted   => sub {
        (/$img_formats_re/o && -f) || return;

        my $basename = basename($_);

        if (exists($source_files{$basename})) {
            say "Adding EXIF metadata to: $_";
            add_exif_info($source_files{$basename}, $_);
        }
        else {
            warn "Couldn't find <<$basename>> into source directory. Skipping...\n";
        }
    }
} => $dest_dir;
