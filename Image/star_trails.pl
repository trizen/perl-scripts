#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 30 January 2015
# Website: https://github.com/trizen

# Merge two or more images together and keep the most intesive pixel colors

use 5.010;
use strict;
use autodie;
use warnings;

use List::Util qw(sum);
use Getopt::Long qw(GetOptions);

require GD;
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
          );

my (@images) = @ARGV;

my @matrix;

sub intensity {
    my ($pixels) = @_;
    defined($pixels) ? sum(@{$pixels}) / 3 : 0;
}

my ($width, $height);

foreach my $image (@images) {

    say "** Processing file `$image'...";

    my $gd = GD::Image->new($image) // do {
        warn "** Can't load file `$image'. Skipping...\n";
        next;
    };

    ($width, $height) = $gd->getBounds;

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
            my $rgb = [$gd->rgb($index)];
            if (intensity($matrix[$x][$y]) < intensity($rgb)) {
                $matrix[$x][$y] = $rgb;
            }
        }
    }
}

$width // die "error: No image has been processed!\n";

say "** Creating the output image `$output_file'...";

my $image = GD::Image->new($width, $height);
foreach my $x (0 .. $width - 1) {
    foreach my $y (0 .. $height - 1) {
        exists($matrix[$x][$y]) or next;
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
