#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 07 November 2015
# Website: https://github.com/trizen

# Replace the light-color pixels with their darken neighbors.

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

# where M is the darkest color from (A, B, C, D, E, F, G, H)

use 5.010;
use strict;
use warnings;

use List::Util qw(min);

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

sub get_pixel {
    $img->rgb($img->getPixel(@_));
}

foreach my $y (1 .. $height - 2) {
    foreach my $x (1 .. $width - 2) {
        my @left  = get_pixel($x - 1, $y);
        my @right = get_pixel($x + 1, $y);

        my @down_left  = get_pixel($x - 1, $y + 1);
        my @down_right = get_pixel($x + 1, $y + 1);

        my @up   = get_pixel($x, $y - 1);
        my @down = get_pixel($x, $y + 1);

        my @up_left  = get_pixel($x - 1, $y - 1);
        my @up_right = get_pixel($x + 1, $y - 1);

        $matrix[$y][$x] =
          $new_img->colorAllocate(
                                  min(($up[0], $down[0], $up_left[0], $up_right[0], $down_left[0], $down_right[0])),
                                  min(($up[1], $down[1], $up_left[1], $up_right[1], $down_left[1], $down_right[1])),
                                  min(($up[2], $down[2], $up_left[2], $up_right[2], $down_left[2], $down_right[2])),
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
