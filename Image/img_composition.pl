#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 15 April 2015
# Edit: 18 September 2016
# Website: https://github.com/trizen

# Compose two images together by merging all the pixels, color by color.

use 5.010;
use strict;
use autodie;
use warnings;

use GD;

use List::Util qw(min);
use Getopt::Long qw(GetOptions);

GD::Image->trueColor(1);

my $output_file      = 'output.png';
my $scale_percentage = 0;

sub usage {
    print <<"USAGE";
usage: $0 [options] [img1] [img2]

options:
    -o  --output         : output file (default: $output_file)
    -s  --scale-percent  : scale images by a given percentage (default: $scale_percentage)

example:
    $0 -s -40 img1.png img2.jpg
USAGE
    exit 2;
}

GetOptions(
           'o|output=s'           => \$output_file,
           's|scale-percentage=i' => \$scale_percentage,
           'h|help'               => \&usage,
          );

sub scale_image {
    my ($img, $scale_percentage) = @_;

    my ($width, $height) = $img->getBounds;

    my $scale_width  = $width + int($scale_percentage / 100 * $width);
    my $scale_height = $height + int($scale_percentage / 100 * $height);

    my $scaled_gd = GD::Image->new($scale_width, $scale_height);
    $scaled_gd->copyResampled($img, 0, 0, 0, 0, $scale_width, $scale_height, $width, $height);

    return $scaled_gd;
}

sub make_matrix {
    my ($file, $scale_percentage) = @_;

    my $img = GD::Image->new($file) // do {
        warn "Can't load image `$file': $!\n";
        return;
    };

    if ($scale_percentage != 0) {
        $img = scale_image($img, $scale_percentage);
    }

    my @matrix;
    my ($width, $height) = $img->getBounds();
    foreach my $x (0 .. $width - 1) {
        foreach my $y (0 .. $height - 1) {
            $matrix[$x][$y] = [$img->rgb($img->getPixel($x, $y))];
        }
    }

    return \@matrix;
}

sub compose_images {
    my ($A, $B) = @_;

    local $| = 1;

    my ($rows, $cols) = (min($#{$A}, $#{$B}), min($#{$A->[0]}, $#{$B->[0]}));

    my @C;
    foreach my $r (0 .. $rows) {
        foreach my $i (0 .. $cols) {
            foreach my $c (0 .. 2) {
                $C[$i][$r][$c] = int(($A->[$r][$i][$c] + $B->[$r][$i][$c]) / 2);
            }
        }
        print "$r of $rows...\r";
    }

    return \@C;
}

sub write_matrix {
    my ($matrix, $file) = @_;

    my ($rows, $cols) = ($#{$matrix}, $#{$matrix->[0]});
    my $img = GD::Image->new($cols + 1, $rows + 1);

    foreach my $y (0 .. $rows) {
        foreach my $x (0 .. $cols) {
            $img->setPixel($x, $y, $img->colorAllocate(@{$matrix->[$y][$x]}));
        }
    }

    open my $fh, '>:raw', $file;
    print $fh lc($file) =~ /\.png\z/
      ? $img->png()
      : $img->jpeg();
    close $fh;

}

say "** Reading images...";
my $A = make_matrix(shift(@ARGV) // usage(), $scale_percentage) // die "error 1: $!";
my $B = make_matrix(shift(@ARGV) // usage(), $scale_percentage) // die "error 2: $!";

say "** Composing images...";
my $C = compose_images($A, $B);

say "** Writing the output image...";
write_matrix($C, $output_file)
  ? (say "** All done!")
  : (die "Error: $!");
