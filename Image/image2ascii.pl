#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 27 August 2015
# Website: https://github.com/trizen

# Generate an ASCII representation for an image

use 5.010;
use strict;
use autodie;
use warnings;

use GD qw();
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

sub avg {
    ($_[0] + $_[1] + $_[2]) / 3;
}

sub img2ascii {
    my ($image) = @_;

    my $img = GD::Image->new($image) // return;
    my ($width, $height) = $img->getBounds;

    if ($size != 0) {
        my $scale_width = $size;
        my $scale_height = int($height / ($width / ($size / 2)));

        my $resized = GD::Image->new($scale_width, $scale_height);
        $resized->copyResampled($img, 0, 0, 0, 0, $scale_width, $scale_height, $width, $height);

        ($width, $height) = ($scale_width, $scale_height);
        $img = $resized;
    }

    my $avg = 0;
    my @averages;

    foreach my $y (0 .. $height - 1) {
        foreach my $x (0 .. $width - 1) {
            my $index = $img->getPixel($x, $y);
            push @averages, avg($img->rgb($index));
            $avg += $averages[-1] / $width / $height;
        }
    }

    unpack("(A$width)*", join('', map { $_ < $avg ? 1 : 0 } @averages));
}

say for img2ascii($ARGV[0] // help(1));
