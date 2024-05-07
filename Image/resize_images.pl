#!/usr/bin/perl

# Author: Trizen
# Date: 30 October 2023
# https://github.com/trizen

# Resize images to a given width or height, keeping aspect ratio.

use 5.036;
use Imager       qw();
use File::Find   qw(find);
use Getopt::Long qw(GetOptions);

my $width  = 'auto';
my $height = 'auto';
my $qtype  = 'mixing';

my $img_formats = '';

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
    -w  --width=i       : resize images to this width (default: $width)
    -h  --height=i      : resize images to this height (default: $height)
    -q  --quality=s     : quality of scaling: 'normal', 'preview' or 'mixing' (default: $qtype)
    -f  --formats=s,s   : specify more image formats (default: @img_formats)

example:
    perl $0 --height=1080 ~/Pictures
EOT

    exit($code);
}

GetOptions(
           'w|width=s'   => \$width,
           'h|height=s'  => \$height,
           'q|quality=s' => \$qtype,
           'f|formats=s' => \$img_formats,
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

    if ($height ne 'auto' and $height > 0) {
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

    $img->write(file => $image);
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
