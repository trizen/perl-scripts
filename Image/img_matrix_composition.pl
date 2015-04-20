#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 15 April 2015
# Website: https://github.com/trizen

# Compisite two images by using a modified matrix multiplication algorithm

use 5.010;
use strict;
use autodie;
use warnings;

use GD;
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

    my %cache;
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
            my $index = $img->getPixel($x, $y);
            $matrix[$x][$y] = ($cache{$index} //= [$img->rgb($index)]);
        }
    }

    return \@matrix;
}

sub multiply_matrices {
    my ($A, $B) = @_;

    local $| = 1;

    my $arows = $#{$A};
    my $brows = $#{$B};
    my $bcols = $#{$B->[0]};

    no warnings 'uninitialized';

    my @C;
    foreach my $r (0 .. $arows) {
        foreach my $c (0 .. $bcols) {
            foreach my $i (0 .. $brows) {
                foreach my $j (0 .. 2) {
                    $C[$r][$c][$j] += ($A->[$r][$i][$j] + $B->[$i][$c][$j]) / 2;    # this line can be changed arbitrarily
                }
            }
        }
        print "$r of $arows...\r";
    }

    return \@C;
}

sub write_matrix {
    my ($matrix, $file) = @_;

    my $img = GD::Image->new($#{$matrix->[0]} + 1, $#{$matrix});

    foreach my $x (0 .. $#{$matrix}) {
        foreach my $y (0 .. $#{$matrix->[0]}) {
            my $color = $img->colorAllocate(map { $_ % 256 } @{$matrix->[$x][$y]});
            $img->setPixel($x, $y, $color);
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

say "** Multiplying matrices...";
my $C = multiply_matrices($A, $B);

say "** Writing the output image...";
write_matrix($C, $output_file)
  ? (say "** All done!")
  : (die "Error: $!");
