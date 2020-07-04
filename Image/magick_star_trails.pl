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

use Image::Magick;
use List::Util qw(min max);
use Getopt::Long qw(GetOptions);

my $output_file   = 'output.png';
my $scale_percent = 0;
my $brightness_f  = 'avg';

my %brightness = (

    # I: http://en.wikipedia.org/wiki/HSL_and_HSV#Lightness
    avg => sub { ($_[0] + $_[1] + $_[2]) / 3 },

    # L: http://en.wikipedia.org/wiki/HSL_and_HSV#Lightness
    hsl => sub { 0.5 * max(@_) + 0.5 * min(@_) },

    # https://en.wikipedia.org/wiki/Relative_luminance
    rl => sub { (0.2126 * $_[0] + 0.7152 * $_[1] + 0.0722 * $_[2]) },

    # http://en.wikipedia.org/wiki/Luma_(video)#Rec._601_luma_versus_Rec._709_luma_coefficients
    luma => sub { (0.299 * $_[0] + 0.587 * $_[1] + 0.114 * $_[2]) },

    # http://alienryderflex.com/hsp.html
    hsp => sub { sqrt(0.299 * ($_[0]**2) + 0.587 * ($_[1]**2) + 0.114 * ($_[2]**2)) },
);

sub help {
    local $" = ", ";
    print <<"HELP";
usage: $0 [options] [files]

options:
    -o  --output         : output file (default: $output_file)
    -s  --scale-percent  : scale image by a given percentage (default: $scale_percent)
    -f  --formula        : formula for the brightness of a pixel (default: $brightness_f)
                           valid values: @{[sort keys %brightness]}

example:
    $0 -o merged.png --scale -20 file1.jpg file2.jpg
HELP
    exit;
}

GetOptions(
           'o|output=s'        => \$output_file,
           's|scale-percent=i' => \$scale_percent,
           'f|formula=s'       => \$brightness_f,
           'h|help'            => \&help,
          )
  or die "Error in command-line arguments!";

if (not exists $brightness{$brightness_f}) {
    local $" = ", ";
    die "[!] Invalid brightness formula: `$brightness_f'.
        Valid values are: @{[sort keys %brightness]}\n";
}

my $lightness_function = $brightness{$brightness_f};

my @matrix;
foreach my $image (@ARGV) {

    say "** Processing file `$image'...";

    my $img = Image::Magick->new;
    my $err = $img->Read($image);

    if ($err) {
        warn "** Can't load file `$image' ($err). Skipping...\n";
        next;
    }

    my ($width, $height) = $img->Get('width', 'height');

    if ($scale_percent != 0) {
        my $scale_width  = $width + int($scale_percent / 100 * $width);
        my $scale_height = $height + int($scale_percent / 100 * $height);
        $img->Resize(width => $scale_width, height => $scale_height);
        ($width, $height) = ($scale_width, $scale_height);
    }

    my @pixels = $img->GetPixels(
                                 map       => 'RGB',
                                 x         => 0,
                                 y         => 0,
                                 width     => $width,
                                 height    => $height,
                                 normalize => 1,
                                );

    my $i = 0;
    while (@pixels) {

        my $x = int($i % $width);
        my $y = int($i / $width);

        my @rgb = splice(@pixels, 0, 3);

        $matrix[$x][$y] //= [0, 0, 0];
        if ($lightness_function->(@{$matrix[$x][$y]}) < $lightness_function->(@rgb)) {
            $matrix[$x][$y] = \@rgb;
        }

        ++$i;
    }
}

@matrix || die "error: No image has been processed!\n";
say "** Creating the output image `$output_file'...";

my $image = Image::Magick->new;
$image->Set(size => @matrix . 'x' . @{$matrix[0]});
$image->ReadImage('canvas:white');

foreach my $x (0 .. $#matrix) {
    foreach my $y (0 .. $#{$matrix[0]}) {
        $image->SetPixel(x => $x, y => $y, color => $matrix[$x][$y]);
    }
}

open my $fh, '>:raw', $output_file;
$image->Write(file => $fh, filename => $output_file);
close $fh;

say "** All done!";
