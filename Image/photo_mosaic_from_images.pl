#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 06 January 2017
# https://github.com/trizen

# A simple RGB mosaic generator from a collection of images, using the pattern from a given image.

use 5.010;
use strict;
use autodie;
use warnings;

use GD qw();
use POSIX qw(ceil);
use List::Util qw(min);
use File::Find qw(find);
use Getopt::Long qw(GetOptions);

GD::Image->trueColor(1);

my $size        = 15;
my $wcrop       = 1 / 2;          # width crop ratio
my $hcrop       = 1 / 6;          # height crop ratio
my $output_file = 'mosaic.png';

sub usage {
    my ($code) = @_;
    print <<"EOT";
usage: $0 [options] [main_image] [photos_dir]

options:
    --size=i   : the size of a mosaic square (default: $size)
    --wcrop=f  : width cropping ratio (default: $wcrop)
    --hcrop=f  : height cropping ratio (default: $hcrop)
    --output=s : output filename (default: $output_file)

example:
    perl $0 --size=20 main.jpg images
EOT
    exit($code);
}

GetOptions(
           'size=i'   => \$size,
           'wcrop=f'  => \$wcrop,
           'hcrop=f'  => \$hcrop,
           'output=s' => \$output_file,
           'h|help'   => sub { usage(0) },
          )
  or die("$0: error in command line arguments\n");

sub analyze_image {
    my ($file, $images) = @_;

    my $img = GD::Image->new($file) || return;

    say "Analyzing: $file";

    $img = resize_image($img);
    my ($width, $height) = $img->getBounds;

    my $red_avg   = 0;
    my $green_avg = 0;
    my $blue_avg  = 0;
    my $avg       = 0;

    my $pixels = $width * $height;
    foreach my $y (0 .. $height - 1) {
        foreach my $x (0 .. $width - 1) {
            my $pixel = $img->getPixel($x, $y);
            my ($red, $green, $blue) = $img->rgb($pixel);

            $avg       += ($red + $green + $blue) / 3 / $pixels;
            $red_avg   += $red / $pixels;
            $green_avg += $green / $pixels;
            $blue_avg  += $blue / $pixels;
        }
    }

    my ($x, $y, $z) = map { ($_ + $avg) / 2 } ($red_avg, $green_avg, $blue_avg);
    push @{$images->[$x][$y][$z]}, $img;
}

sub resize_image {
    my ($image) = @_;

    # Get image dimensions
    my ($width, $height) = $image->getBounds();

    # File is already at the wanted resolution
    if ($width == $size and $height == $size) {
        return $image;
    }

    # Get the minimum ratio
    my $min_r = min($width / $size, $height / $size);

    my $n_width  = sprintf('%.0f', $width / $min_r);
    my $n_height = sprintf('%.0f', $height / $min_r);

    # Create a new GD image with the new dimensions
    my $gd = GD::Image->new($n_width, $n_height);
    $gd->copyResampled($image, 0, 0, 0, 0, $n_width, $n_height, $width, $height);

    # Create a new GD image with the wanted dimensions
    my $cropped = GD::Image->new($size, $size);

    # Crop from left and right
    if ($n_width > $size) {
        my $diff = $n_width - $size;
        my $left = ceil($diff * $wcrop);
        $cropped->copy($gd, 0, 0, $left, 0, $size, $size);
    }

    # Crop from top and bottom
    elsif ($n_height > $size) {
        my $diff = $n_height - $size;
        my $top  = int($diff * $hcrop);
        $cropped->copy($gd, 0, 0, 0, $top, $size, $size);
    }

    # No crop needed
    else {
        $cropped = $gd;
    }

    return $cropped;
}

sub find_closest {
    my ($red, $green, $blue, $images) = @_;

    my ($R, $G, $B);

    # Finds the closest red value
    for (my $j = 0 ; ; ++$j) {
        if (exists($images->[$red + $j]) and defined($images->[$red + $j])) {
            $R = $images->[$red + $j];
            last;
        }

        if ($red - $j >= 0 and defined($images->[$red - $j])) {
            $R = $images->[$red - $j];
            last;
        }
    }

    # Finds the closest green value
    for (my $j = 0 ; ; ++$j) {
        if (exists($R->[$green + $j]) and defined($R->[$green + $j])) {
            $G = $R->[$green + $j];
            last;
        }

        if ($green - $j >= 0 and defined($R->[$green - $j])) {
            $G = $R->[$green - $j];
            last;
        }
    }

    # Finds the closest blue value
    for (my $j = 0 ; ; ++$j) {
        if (exists($G->[$blue + $j]) and defined($G->[$blue + $j])) {
            $B = $G->[$blue + $j];
            last;
        }

        if ($blue - $j >= 0 and defined($G->[$blue - $j])) {
            $B = $G->[$blue - $j];
            last;
        }
    }

    $B->[rand @$B];    # returns a random image (when there are more candidates)
}

my $main_file = shift(@ARGV) // usage(2);
my @photo_dirs = (@ARGV ? @ARGV : usage(2));

my $img = GD::Image->new($main_file) || die "Can't load image `$main_file`: $!";

if ($size <= 0) {
    die "$0: size must be greater than zero (got: $size)\n";
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

my ($width, $height) = $img->getBounds;
my $mosaic = GD::Image->new($width, $height);

foreach my $y (0 .. $height / $size) {
    foreach my $x (0 .. $width / $size) {
        $mosaic->copy(find_closest($img->rgb($img->getPixel($x * $size, $y * $size)), \@images),
                      $x * $size, $y * $size, 0, 0, $size, $size);
    }
}

open my $fh, '>:raw', $output_file;
print $fh (
             $output_file =~ /\.png\z/i
           ? $mosaic->png
           : $mosaic->jpeg
          );
close $fh;
