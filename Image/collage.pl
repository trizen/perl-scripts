#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 23 March 2021
# https://github.com/trizen

# Create a collage from a collection of images.

use 5.010;
use strict;
use autodie;
use warnings;

use GD           qw();
use POSIX        qw(ceil);
use List::Util   qw(min);
use File::Find   qw(find);
use Getopt::Long qw(GetOptions);

GD::Image->trueColor(1);

my $size        = 350;
my $wsize       = undef;
my $hsize       = undef;
my $wcrop       = 1 / 2;           # width crop ratio
my $hcrop       = 1 / 5;           # height crop ratio
my $output_file = 'collage.png';

my $width  = undef;
my $height = undef;

sub usage {
    my ($code) = @_;
    print <<"EOT";
usage: $0 [options] [files / directories]

options:
    --size=i   : the length of a square tile (default: $size)
    --wsize=i  : the width of a tile (default: $size)
    --hsize=i  : the height of a tile (default: $size)
    --wcrop=f  : width cropping ratio (default: $wcrop)
    --hcrop=f  : height cropping ratio (default: $hcrop)
    --width=i  : minimum width of the collage (default: auto)
    --height=i : minimum height of the collage (default: auto)
    --output=s : output filename (default: $output_file)

example:
    $0 --size=100 ~/Pictures
EOT
    exit($code);
}

GetOptions(
           'size=i'   => \$size,
           'wsize=i'  => \$wsize,
           'hsize=i'  => \$hsize,
           'wcrop=f'  => \$wcrop,
           'hcrop=f'  => \$hcrop,
           'width=i'  => \$width,
           'height=i' => \$height,
           'output=s' => \$output_file,
           'h|help'   => sub { usage(0) },
          )
  or die("$0: error in command line arguments\n");

sub analyze_image {
    my ($file, $images) = @_;

    my $img = eval { GD::Image->new($file) } || return;

    say "Analyzing: $file";

    $img = resize_image($img);

    push @$images, $img;
}

sub resize_image {
    my ($image) = @_;

    # Get image dimensions
    my ($width, $height) = $image->getBounds();

    # File is already at the wanted resolution
    if ($width == $wsize and $height == $hsize) {
        return $image;
    }

    # Get the minimum ratio
    my $min_r = min($width / $wsize, $height / $hsize);

    my $n_width  = sprintf('%.0f', $width / $min_r);
    my $n_height = sprintf('%.0f', $height / $min_r);

    # Create a new GD image with the new dimensions
    my $gd = GD::Image->new($n_width, $n_height);
    $gd->copyResampled($image, 0, 0, 0, 0, $n_width, $n_height, $width, $height);

    # Create a new GD image with the wanted dimensions
    my $cropped = GD::Image->new($wsize, $hsize);

    # Crop from left and right
    if ($n_width > $wsize) {
        my $diff = $n_width - $wsize;
        my $left = ceil($diff * $wcrop);
        $cropped->copy($gd, 0, 0, $left, 0, $wsize, $hsize);
    }

    # Crop from top and bottom
    elsif ($n_height > $hsize) {
        my $diff = $n_height - $hsize;
        my $top  = int($diff * $hcrop);
        $cropped->copy($gd, 0, 0, 0, $top, $wsize, $hsize);
    }

    # No crop needed
    else {
        $cropped = $gd;
    }

    return $cropped;
}

my @photo_dirs = (@ARGV ? @ARGV : usage(2));

$wsize //= $size;
$hsize //= $size;

if ($wsize <= 0 or $hsize <= 0) {
    die "$0: size must be greater than zero (got: [$size, $wsize, $hsize])\n";
}

my @images;    # stores all the image objects

find {
    no_chdir => 1,
    wanted   => sub {
        if (/\.(?:jpe?g|png)\z/i) {
            analyze_image($_, \@images);
        }
    },
} => @photo_dirs;

my $images_len = scalar(@images);

$width  //= int(sqrt($images_len)) * $wsize;
$height //= $width;

if ($width % $wsize != 0) {
    $width += ($wsize - ($width % $wsize));
}

if ($height % $hsize != 0) {
    $height += ($hsize - ($height % $hsize));
}

while (($width / $wsize) * ($height / $hsize) > $images_len) {
    $height -= $hsize;
}

while (($width / $wsize) * ($height / $hsize) < $images_len) {
    $height += $hsize;
}

my $collage = GD::Image->new($width, $height);

foreach my $y (0 .. $height / $hsize - 1) {
    foreach my $x (0 .. $width / $wsize - 1) {
        my $source = shift(@images) // last;
        $collage->copy($source, $x * $wsize, $y * $hsize, 0, 0, $wsize, $hsize);
    }
}

open my $fh, '>:raw', $output_file;
print $fh (
             $output_file =~ /\.png\z/i
           ? $collage->png(9)
           : $collage->jpeg(90)
          );
close $fh;
