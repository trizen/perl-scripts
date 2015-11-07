#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 07 November 2015
# Website: https://github.com/trizen

# Replace the light-color pixels with the difference between the brightest and darkest neighbours.

#   _________________
#  |     |     |     |
#  |  A  |  B  |  C  |
#  |_____|_____|_____|         _____
#  |     |     |     |        |     |
#  |  H  |     |  D  |   -->  |  M  |
#  |_____|_____|_____|        |_____|
#  |     |     |     |
#  |  G  |  F  |  E  |
#  |_____|_____|_____|

# where M is the average color of (max(A..H) - min(A..H))

use 5.010;
use strict;
use warnings;

use List::Util qw(min max sum);

use GD;
GD::Image->trueColor(1);

sub help {
    my ($exit_code) = @_;

    print <<"EOT";
usage: $0 [input image] [output image]
EOT

    exit($exit_code // 0);
}

my $in_file  = shift(@ARGV) // help(2);
my $out_file = shift(@ARGV) // 'output.png';

my $img = GD::Image->new($in_file);

my @matrix = ([]);
my ($width, $height) = $img->getBounds;

my $new_img = GD::Image->new($width, $height);

sub diff {
    max(@_) - min(@_);
}

sub avg {
    (int(sum(@_) / @_)) x 3;
}

foreach my $y (1 .. $height - 2) {
    foreach my $x (1 .. $width - 2) {
        my $left  = $img->getPixel($x - 1, $y);
        my $right = $img->getPixel($x + 1, $y);

        my $down_left  = $img->getPixel($x - 1, $y + 1);
        my $down_right = $img->getPixel($x + 1, $y + 1);

        my $up   = $img->getPixel($x, $y - 1);
        my $down = $img->getPixel($x, $y + 1);

        my $up_left  = $img->getPixel($x - 1, $y - 1);
        my $up_right = $img->getPixel($x + 1, $y - 1);

        my @left  = $img->rgb($left);
        my @right = $img->rgb($right);

        my @down_left  = $img->rgb($down_left);
        my @down_right = $img->rgb($down_right);

        my @up   = $img->rgb($up);
        my @down = $img->rgb($down);

        my @up_left  = $img->rgb($up_left);
        my @up_right = $img->rgb($up_right);

        $matrix[$y][$x] =
          $new_img->colorAllocate(
                                  avg(
                                      diff(($up[0], $down[0], $up_left[0], $up_right[0], $down_left[0], $down_right[0])),
                                      diff(($up[1], $down[1], $up_left[1], $up_right[1], $down_left[1], $down_right[1])),
                                      diff(($up[2], $down[2], $up_left[2], $up_right[2], $down_left[2], $down_right[2]))
                                     ),
                                 );
    }
}

for my $y (1 .. $height - 2) {
    for my $x (1 .. $width - 2) {
        $new_img->setPixel($x, $y, $matrix[$y][$x]);
    }
}

open(my $fh, '>:raw', $out_file) or die "Can't open `$out_file' for write: $!";
print $fh (
             $out_file =~ /\.png\z/i ? $new_img->png
           : $out_file =~ /\.gif\z/i ? $new_img->gif
           :                           $new_img->jpeg
          );
close $fh;
