#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 14 June 2015
# Edit: 19 March 2017
# http://github.com/trizen

# A generic image auto-cropper which adapt itself to any background color.

use 5.010;
use strict;
use warnings;

use GD qw();

use Getopt::Long qw(GetOptions);
use File::Basename qw(basename);
use File::Spec::Functions qw(catfile);

# Set true color
GD::Image->trueColor(1);

# Autoflush mode
local $| = 1;

my $tolerance = 5;
my $invisible = 0;

my $jpeg_quality    = 95;
my $png_compression = 7;

my $directory = 'Cropped images';

sub help {
    my ($code) = @_;
    print <<"EOT";
usage: $0 [options] [images]

options:
    -t --tolerance=i    : tolerance value for the background color
                          default: $tolerance

    -i --invisible!     : make the background transparent after cropping
                          default: ${$invisible ? \'true' : \'false'}

    -p --png-compress=i : the compression level for PNG images
                          default: $png_compression

    -j --jpeg-quality=i : the quality value for JPEG images
                          default: $jpeg_quality

    -d --directory=s    : directory where to create the cropped images
                          default: "$directory"

example:
    perl $0 -t 10 *.png
EOT
    exit($code // 0);
}

GetOptions(
           'd|directory=s'       => \$directory,
           'i|invisible!'        => \$invisible,
           't|tolerance=i'       => \$tolerance,
           'p|png-compression=i' => \$png_compression,
           'j|jpeg-quality=i'    => \$jpeg_quality,
           'h|help'              => sub { help(0) },
          )
  or die("$0: error in command line arguments!\n");

{
    my %cache;

    sub is_background {
        my ($img, $index, $bg_rgb) = @_;
        my $rgb = ($cache{$index} //= [$img->rgb($index)]);
        abs($rgb->[0] - $bg_rgb->[0]) <= $tolerance
          and abs($rgb->[1] - $bg_rgb->[1]) <= $tolerance
          and abs($rgb->[2] - $bg_rgb->[2]) <= $tolerance;
    }
}

sub make_invisible_bg {
    my ($img, $transparent, $bg_rgb, $width, $height) = @_;

    foreach my $x (0 .. $width) {
        foreach my $y (0 .. $height) {
            if (is_background($img, $img->getPixel($x, $y), $bg_rgb)) {
                $img->setPixel($x, $y, $transparent);
            }
        }
    }
}

sub autocrop {
    my @images = @_;

    foreach my $file (@images) {
        my $img = GD::Image->new($file);

        if (not defined $img) {
            warn "[!] Can't process image `$file': $!\n";
            next;
        }

        my ($width, $height) = $img->getBounds();

        $width  -= 1;
        $height -= 1;

        my $C = (2 * $width + 1 + 2 * $height + 1);
        my @bg_rgb = (0, 0, 0);

        foreach my $x (0 .. $width) {
            for my $arr ([map { $_ / $C } $img->rgb($img->getPixel($x, 0))],
                         [map { $_ / $C } $img->rgb($img->getPixel($x, $height))]) {
                $bg_rgb[0] += $arr->[0];
                $bg_rgb[1] += $arr->[1];
                $bg_rgb[2] += $arr->[2];
            }
        }

        foreach my $y (0 .. $height) {
            for my $arr ([map { $_ / $C } $img->rgb($img->getPixel(0, $y))],
                         [map { $_ / $C } $img->rgb($img->getPixel($width, $y))]) {
                $bg_rgb[0] += $arr->[0];
                $bg_rgb[1] += $arr->[1];
                $bg_rgb[2] += $arr->[2];
            }
        }

        print "Cropping: $file";

        my $top;
        my $bottom;
      TB: foreach my $y (1 .. $height) {
            foreach my $x (1 .. $width) {

                if (not defined $top) {
                    if (not is_background($img, $img->getPixel($x, $y), \@bg_rgb)) {
                        $top = $y - 1;
                    }
                }

                if (not defined $bottom) {
                    if (not is_background($img, $img->getPixel($x, $height - $y), \@bg_rgb)) {
                        $bottom = $height - $y + 1;
                    }
                }

                if (defined $top and defined $bottom) {
                    last TB;
                }
            }
        }

        if (not defined $top or not defined $bottom) {
            say " - fail!";
            next;
        }

        my $left;
        my $right;
      LR: foreach my $x (1 .. $width) {
            foreach my $y (1 .. $height) {
                if (not defined $left) {
                    if (not is_background($img, $img->getPixel($x, $y), \@bg_rgb)) {
                        $left = $x - 1;
                    }
                }

                if (not defined $right) {
                    if (not is_background($img, $img->getPixel($width - $x, $y), \@bg_rgb)) {
                        $right = $width - $x + 1;
                    }
                }

                if (defined $left and defined $right) {
                    last LR;
                }
            }
        }

        if (not defined $left or not defined $right) {
            say " - fail!";
            next;
        }

        my $cropped = GD::Image->new($right - $left + 1, $bottom - $top + 1);

        my $index;
        if ($invisible) {
            $index = $cropped->colorAllocateAlpha(int(rand(256)), int(rand(256)), int(rand(256)), 0);
            $cropped->filledRectangle(0, 0, $cropped->width, $cropped->height, $index);
            $cropped->transparent($index);
        }

        $cropped->copyResized(
                              $img,
                              0,          # destX
                              0,          # destY
                              $left,      # srcX
                              $top,       # srcY
                              $right,     # destW
                              $bottom,    # destH
                              $right,     # srcW
                              $bottom,    # srcH
                             );

        my $name = catfile($directory, basename($file));

        if ($invisible) {
            make_invisible_bg($cropped, $index, \@bg_rgb, $cropped->width - 1, $cropped->height - 1);
            $name =~ s/\.\w+\z/.png/;
        }

        open my $fh, '>:raw', $name or die "Can't create file `$name': $!";
        print $fh (
                     $name =~ /\.png\z/i ? $cropped->png($png_compression)
                   : $name =~ /\.gif\z/i ? $cropped->gif
                   :                       $cropped->jpeg($jpeg_quality)
                  );
        close $fh;

        say " - ok!";
    }
}

@ARGV || help(1);

if (not -d $directory) {
    mkdir($directory) || die "Can't mkdir `$directory': $!";
}

autocrop(@ARGV);
