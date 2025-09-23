#!/usr/bin/perl

# Author: Trizen
# Date: 10 August 2025
# Edit: 23 Setepmber 2025
# https://github.com/trizen

# Hard-rotate images that contain the "Orientation" EXIF tag specified as "Rotate 90 CW" or "Rotate 270 CW".

use 5.036;
use Imager;
use Image::ExifTool qw(ImageInfo);
use File::Find      qw(find);
use Getopt::Long    qw(GetOptions);

my $img_formats   = '';
my $preserve_attr = 0;

my @img_formats = qw(
  jpeg
  jpg
);

sub usage ($code) {
    local $" = ",";
    print <<"EOT";
usage: $0 [options] [dirs | files]

options:
    -f  --formats=s,s : specify more image formats (default: @img_formats)
    -p  --preserve!   : preserve original file timestamps and permissions

examples:

    $0 -p *.jpg

EOT

    exit($code);
}

GetOptions(
           'f|formats=s' => \$img_formats,
           'p|preserve!' => \$preserve_attr,
           'help'        => sub { usage(0) },
          )
  or die("Error in command line arguments");

sub hard_rotate_image ($file) {

    my $info        = ImageInfo($file);
    my $orientation = $info->{Orientation};

    if (defined($orientation) and $orientation =~ /^Rotate (\d+) CW/) {

        my $angle = $1;
        say "-> Rotating image by $angle degrees clockwise...";

        my $img = Imager->new(file => $file) or die Imager->errstr();
        $img = $img->rotate(degrees => $angle);

        my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat($file);

        unlink($file);
        $img->write(file => $file) or do {
            warn "Failed to rewrite image: ", $img->errstr;
            return;
        };

        # Set the original ownership of the image
        chown($uid, $gid, $file);

        if ($preserve_attr) {

            # Set the original modification time
            utime($atime, $mtime, $file)
              or warn "Can't change timestamp: $!\n";

            # Set original permissions
            chmod($mode & 07777, $file)
              or warn "Can't change permissions: $!\n";
        }

    }
}

@ARGV || usage(1);

push @img_formats, map { quotemeta } split(/\s*,\s*/, $img_formats);

my $img_formats_re = do {
    local $" = '|';
    qr/\.(@img_formats)\z/i;
};

find {
    no_chdir => 1,
    wanted   => sub {
        (/$img_formats_re/o && -f) || return;
        say ":: Processing: $_";
        hard_rotate_image($_);
    }
} => @ARGV;
