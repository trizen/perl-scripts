#!/usr/bin/perl

# Author: Trizen
# Date: 29 April 2022
# https://github.com/trizen

# Generate an ASCII representation for an image, using only digits.

# See also:
#   https://github.com/TotalTechGeek/pictoprime

use 5.010;
use strict;
use autodie;
use warnings;

use GD qw();
use List::Util qw(max);
use Getopt::Long qw(GetOptions);

GD::Image->trueColor(1);

my $size = 80;

sub help {
    my ($code) = @_;
    print <<"HELP";
usage: $0 [options] [files]

options:
    -w  --width=i : width size of the ASCII image (default: $size)

example:
    perl $0 --width 200 image.png
HELP
    exit($code);
}

GetOptions('w|width=s' => \$size,
           'h|help'    => sub { help(0) },)
  or die "Error in command-line arguments!";

sub map_value {
    my ($value, $in_min, $in_max, $out_min, $out_max) = @_;
    ($value - $in_min) * ($out_max - $out_min) / ($in_max - $in_min) + $out_min;
}

my @digits = split(//, "7772299408");

#my @digits = 0..9;

sub img2digits {
    my ($image) = @_;

    my $img = GD::Image->new($image) // return;
    my ($width, $height) = $img->getBounds;

    if ($size != 0) {
        my $scale_width  = $size;
        my $scale_height = int($height / ($width / ($size / 2)));

        my $resized = GD::Image->new($scale_width, $scale_height);
        $resized->copyResampled($img, 0, 0, 0, 0, $scale_width, $scale_height, $width, $height);

        ($width, $height) = ($scale_width, $scale_height);
        $img = $resized;
    }

    my @values;

    foreach my $y (0 .. $height - 1) {
        foreach my $x (0 .. $width - 1) {
            my $index = $img->getPixel($x, $y);
            my ($r, $g, $b) = $img->rgb($index);
            my $value = max($r, $g, $b);
            push @values, $digits[map_value($value, 0, 255, 0, $#digits)];
        }
    }

    unpack("(A$width)*", join('', @values));
}

say for img2digits($ARGV[0] // help(1));
