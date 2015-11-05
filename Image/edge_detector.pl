#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 05 November 2015
# Website: https://github.com/trizen

# A very basic edge detector, which highlights the edges in an image.

use 5.010;
use strict;
use warnings;

use GD;
GD::Image->trueColor(1);

use Getopt::Long qw(GetOptions);

my $tolerance = 15;    # lower tolerance => more noise

GetOptions('t|tolerance=f' => \$tolerance,
           'h|help'        => sub { help(0) },)
  or die "Error in command-line arguments!";

sub help {
    my ($exit_code) = @_;

    print <<"EOT";
usage: $0 [options] [input image] [output image]

options:
        -t  --tolerance=f : tolerance value for edge-detection
                             (default: $tolerance)

example:
    perl $0 -t=5 input.png output.png
EOT

    exit($exit_code // 0);
}

my $in_file  = shift(@ARGV) // help(2);
my $out_file = shift(@ARGV) // 'output.png';

my $img = GD::Image->new($in_file);

my @matrix = ([]);
my ($width, $height) = $img->getBounds;

sub avg {
    ($_[0] + $_[1] + $_[2]) / 3;
}

foreach my $y (1 .. $height - 2) {
    foreach my $x (1 .. $width - 2) {
        my $left  = $img->getPixel($x - 1, $y);
        my $right = $img->getPixel($x + 1, $y);

        my $up   = $img->getPixel($x, $y - 1);
        my $down = $img->getPixel($x, $y + 1);

        my $left_avg  = avg($img->rgb($left));
        my $right_avg = avg($img->rgb($right));

        my $up_avg   = avg($img->rgb($up));
        my $down_avg = avg($img->rgb($down));

        if (   abs($left_avg - $right_avg) / 255 * 100 > $tolerance
            or abs($up_avg - $down_avg) / 255 * 100 > $tolerance) {
            $matrix[$y][$x] = 0;
        }
    }
}

my $new_img = GD::Image->new($width, $height);

my $bg_color = $new_img->colorAllocate(0,   0,   0);
my $fg_color = $new_img->colorAllocate(255, 255, 255);

for my $y (0 .. $height - 1) {
    for my $x (0 .. $width - 1) {
        $new_img->setPixel($x, $y, defined($matrix[$y][$x]) ? $fg_color : $bg_color);
    }
}

open(my $fh, '>:raw', $out_file) or die "Can't open `$out_file' for write: $!";
print $fh (
             $out_file =~ /\.png\z/i ? $new_img->png
           : $out_file =~ /\.gif\z/i ? $new_img->gif
           :                           $new_img->jpeg
          );
close $fh;
