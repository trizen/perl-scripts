#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 30 January 2015
# Edited: 31 January 2015
# Website: https://github.com/trizen

# Merge two or more images together and keep the most intensive pixel colors

use 5.010;
use strict;
use autodie;
use warnings;

use GD;
use Getopt::Long qw(GetOptions);

GD::Image->trueColor(1);

my $output_file = 'output.png';
my $file_format = 'png';

my $png_compression = 9;
my $jpeg_quality    = 90;

my $scale_percent = 0;

sub help {
    print <<"HELP";
usage: $0 [options] [files]

options:
    -o  --output          : output file (default: $output_file)
    -f  --format          : image format (default: $file_format)
    -q  --jpeg-quality    : JPEG quality (default: $jpeg_quality)
    -c  --png-compression : PNG compression level (default: $png_compression)
    -s  --scale-percent   : scale image by a given percentage (default: $scale_percent)

example:
    $0 -o merged.png --scale -20 file1.jpg file2.jpg
HELP
    exit;
}

GetOptions(
           'o|output=s'          => \$output_file,
           'f|format=s'          => \$file_format,
           'q|jpeg-quality=i'    => \$jpeg_quality,
           'c|png-compression=i' => \$png_compression,
           's|scale-percent=i'   => \$scale_percent,
           'h|help'              => \&help,
          )
  or die "Error in command-line arguments!";

sub intensity {
    ($_[0] + $_[1] + $_[2]) / 3;
}

my @matrix;
my %color_cache;
my %intensity_cache;
foreach my $image (@ARGV) {

    say "** Processing file `$image'...";

    my $gd = GD::Image->new($image) // do {
        warn "** Can't load file `$image'. Skipping...\n";
        next;
    };

    my ($width, $height) = $gd->getBounds;

    if ($scale_percent != 0) {
        my $scale_width  = $width + int($scale_percent / 100 * $width);
        my $scale_height = $height + int($scale_percent / 100 * $height);

        my $scaled_gd = GD::Image->new($scale_width, $scale_height);
        $scaled_gd->copyResampled($gd, 0, 0, 0, 0, $scale_width, $scale_height, $width, $height);

        ($width, $height) = ($scale_width, $scale_height);
        $gd = $scaled_gd;
    }

    foreach my $x (0 .. $width - 1) {
        foreach my $y (0 .. $height - 1) {
            my $index = $gd->getPixel($x, $y);
            $matrix[$x][$y] //= [0, 0, 0];
            if (intensity(@{$matrix[$x][$y]}) <
                ($intensity_cache{$index} //= (intensity(@{$color_cache{$index} //= [$gd->rgb($index)]})))) {
                $matrix[$x][$y] = $color_cache{$index};
            }
        }
    }
}

@matrix || die "error: No image has been processed!\n";
say "** Creating the output image `$output_file'...";

my $image = GD::Image->new($#matrix + 1, $#{$matrix[0]} + 1);
foreach my $x (0 .. $#matrix) {
    foreach my $y (0 .. $#{$matrix[0]}) {
        my $color = $image->colorAllocate(@{$matrix[$x][$y]});
        $image->setPixel($x, $y, $color);
    }
}

open my $fh, '>:raw', $output_file;
print $fh lc($file_format) =~ /png/
  ? $image->png($png_compression)
  : $image->jpeg($jpeg_quality);
close $fh;

say "** All done!";
