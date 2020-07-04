#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 14 June 2015
# http://github.com/trizen

# Auto-crop a list of images that have a white background.

use 5.010;
use strict;
use warnings;

use GD qw();

use File::Basename qw(basename);
use File::Spec::Functions qw(catfile);

# Set true color
GD::Image->trueColor(1);

# Autoflush mode
local $| = 1;

my $dir = 'Cropped images';

sub check {
    my ($img, $width, $height) = @_;

    my $check = sub {
        foreach my $sub (@_) {
            $sub->() == 0 or return;
        }
        1;
    };

    my $w_lt_h = $width < $height;
    my $min = $w_lt_h ? $width : $height;

    my %seen;

    # Spiral in to smaller gaps
    # -- this algorithm needs to be improved --
    for (my $i = int(sqrt($min)) ; $i >= 1 ; $i--) {
        foreach my $j (1 .. $min) {

            next if $j % $i;
            next if $seen{$j}++;

            if (
                not $check->(
                             sub { $img->getPixel($j,     0) },
                             sub { $img->getPixel(0,      $j) },
                             sub { $img->getPixel($j,     $height) },
                             sub { $img->getPixel($width, $j) },
                            )
              ) {
                return;
            }
        }
    }

    if ($w_lt_h) {
        foreach my $y ($width + 1 .. $height) {
            if (not $check->(sub { $img->getPixel(0, $y) }, sub { $img->getPixel($width, $y) })) {
                return;
            }
        }
    }
    else {
        foreach my $x ($height + 1 .. $width) {
            if (not $check->(sub { $img->getPixel($x, 0) }, sub { $img->getPixel($x, $height) })) {
                return;
            }
        }
    }

    return 1;
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

        print "Checking: $file";
        check($img, $width, $height) || do {
            print " - fail!\n";
            next;
        };

        print " - ok!\n";
        print "Cropping: $file";

        my $top;
        my $bottom;
      TB: foreach my $y (1 .. $height) {
            foreach my $x (1 .. $width) {

                if (not defined $top) {
                    if ($img->getPixel($x, $y)) {
                        $top = $y - 1;
                    }
                }

                if (not defined $bottom) {
                    if ($img->getPixel($x, $height - $y)) {
                        $bottom = $height - $y + 1;
                    }
                }

                if (defined $top and defined $bottom) {
                    last TB;
                }
            }
        }

        my $left;
        my $right;
      LR: foreach my $x (1 .. $width) {
            foreach my $y (1 .. $height) {
                if (not defined $left) {
                    if ($img->getPixel($x, $y)) {
                        $left = $x - 1;
                    }
                }

                if (not defined $right) {
                    if ($img->getPixel($width - $x, $y)) {
                        $right = $width - $x + 1;
                    }
                }

                if (defined $left and defined $right) {
                    last LR;
                }
            }
        }

        my $cropped = GD::Image->new($right - $left + 1, $bottom - $top + 1);
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

        my $name = catfile($dir, basename($file));

        open my $fh, '>:raw', $name or die "Can't create file `$name': $!";
        print $fh ($name =~ /\.png\z/i ? $cropped->png : $cropped->jpeg);
        close $fh;

        print " - ok!\n";
    }
}

@ARGV || die "usage: $0 [images]\n";

if (not -d $dir) {
    mkdir($dir) || die "Can't mkdir `$dir': $!";
}

autocrop(@ARGV);
