#!/usr/bin/perl

# Author: Trizen
# Date: 30 October 2023
# Edit: 08 August 2024
# https://github.com/trizen

# Resize images to a given width or height, keeping aspect ratio.

use 5.036;
use Imager       qw();
use File::Find   qw(find);
use List::Util   qw(min max);
use Getopt::Long qw(GetOptions);

my $width  = 'auto';
my $height = 'auto';
my $min    = 'auto';
my $max    = 'auto';
my $qtype  = 'mixing';

my $img_formats   = '';
my $preserve_attr = 0;

my @img_formats = qw(
  jpeg
  jpg
  png
);

sub usage ($code) {
    local $" = ",";
    print <<"EOT";
usage: $0 [options] [dirs | files]

options:
    -w  --width=i     : resize images to this width
    -h  --height=i    : resize images to this height

        --min=i       : resize images to have the smallest side equal to this
        --max=i       : resize images to have the largest side equal to this

    -q  --quality=s   : quality of scaling: 'normal', 'preview' or 'mixing' (default: $qtype)
    -f  --formats=s,s : specify more image formats (default: @img_formats)
    -p  --preserve!   : preserve original file timestamps and permissions

examples:

    $0 --min=1080 *.jpg     # smallest side = 1080 pixels
    $0 --height=1080 *.jpg  # height = 1080 pixels

EOT

    exit($code);
}

GetOptions(
           'w|width=i'   => \$width,
           'h|height=i'  => \$height,
           'minimum=i'   => \$min,
           'maximum=i'   => \$max,
           'q|quality=s' => \$qtype,
           'f|formats=s' => \$img_formats,
           'p|preserve!' => \$preserve_attr,
           'help'        => sub { usage(0) },
          )
  or die("Error in command line arguments");

push @img_formats, map { quotemeta } split(/\s*,\s*/, $img_formats);

my $img_formats_re = do {
    local $" = '|';
    qr/\.(@img_formats)\z/i;
};

sub resize_image ($image) {

    my $img = Imager->new(file => $image) or do {
        warn "Failed to load <<$image>>: ", Imager->errstr();
        return;
    };

    my ($curr_width, $curr_height) = ($img->getwidth, $img->getheight);

    if ($min ne 'auto' and $min > 0) {

        if (min($curr_width, $curr_height) <= $min) {
            say "Image too small to resize";
            return;
        }

        if ($curr_width < $curr_height) {
            $img = $img->scale(xpixels => $min, qtype => $qtype);
        }
        else {
            $img = $img->scale(ypixels => $min, qtype => $qtype);
        }
    }
    elsif ($max ne 'auto' and $max > 0) {

        if (max($curr_width, $curr_height) <= $max) {
            say "Image too small to resize";
            return;
        }

        if ($curr_height > $curr_width) {
            $img = $img->scale(ypixels => $max, qtype => $qtype);
        }
        else {
            $img = $img->scale(xpixels => $max, qtype => $qtype);
        }
    }
    elsif ($height ne 'auto' and $height > 0) {
        if ($curr_height <= $height) {
            say "Image too small to resize";
            return;
        }
        $img = $img->scale(ypixels => $height, qtype => $qtype);
    }
    elsif ($width ne 'auto' and $width > 0) {
        if ($curr_width <= $width) {
            say "Image too small to resize";
            return;
        }
        $img = $img->scale(xpixels => $width, qtype => $qtype);
    }
    else {
        die "No --width or --height specified...";
    }

    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat($image);

    $img->write(file => $image) or do {
        warn "Failed to rewrite image: ", $img->errstr;
        return;
    };

    # Set the original ownership of the image
    chown($uid, $gid, $image);

    if ($preserve_attr) {

        # Set the original modification time
        utime($atime, $mtime, $image)
          or warn "Can't change timestamp: $!\n";

        # Set original permissions
        chmod($mode & 07777, $image)
          or warn "Can't change permissions: $!\n";
    }

    return 1;
}

@ARGV || usage(1);

find {
    no_chdir => 1,
    wanted   => sub {
        (/$img_formats_re/o && -f) || return;
        say "Resizing: $_";
        resize_image($_);
    }
} => @ARGV;
