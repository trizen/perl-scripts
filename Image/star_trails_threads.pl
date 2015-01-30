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
use threads;

use Data::Dump qw(pp);
use List::Util qw(sum);
use Getopt::Long qw(GetOptions);

require GD;
GD::Image->trueColor(1);

my $output_file = 'output.png';
my $file_format = 'png';

my $png_compression = 9;
my $jpeg_quality    = 90;

my $max_threads   = 4;
my $scale_percent = 0;

sub help {
    print <<"HELP";
usage: $0 [options] [files]

options:
    -o  --output          : output file (default: $output_file)
    -f  --format          : image format (default: $file_format)
    -t  --threads         : the maximum number of threads (default: $max_threads)
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
           't|threads=i'         => \$max_threads,
           'h|help'              => \&help,
          );

sub intensity {
    my ($pixels) = @_;
    defined($pixels) ? sum(@{$pixels}) / 3 : 0;
}

my @matrix;

sub update_matrix {
    my ($pixels, $cols, $rows) = @_;
    foreach my $x (0 .. $cols) {
        foreach my $y (0 .. $rows) {
            if (intensity($matrix[$x][$y]) < intensity($pixels->[$x][$y])) {
                $matrix[$x][$y] = $pixels->[$x][$y];
            }
        }
    }
}

my ($cols, $rows) = (0, 0);

sub join_thread {
    my ($thread) = @_;

    say "** Joining thread...";
    my ($pixels, $x, $y) = $thread->join;

    update_matrix($pixels, $x, $y);

    if (my $err = $thread->error()) {
        warn("Thread error: $err\n");
    }

    $cols = $x if $x > $cols;
    $rows = $y if $y > $rows;

    say "** Matrix updated...";
}

my @threads;
foreach my $image (@ARGV) {
    push @threads, scalar threads->create(
        {
         'context' => 'list',
        },
        sub {

            my @pixels;
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
                    $pixels[$x][$y] = [$gd->rgb($index)];
                }
            }

            (\@pixels, $width - 1, $height - 1);
        }
    );

    if (@threads >= $max_threads) {
        join_thread(shift @threads);
    }
}

while (defined(my $thread = shift @threads)) {
    join_thread($thread);
}

$cols || $rows || die "error: No image has been processed!\n";

my $image = GD::Image->new($cols + 1, $rows + 1);
foreach my $x (0 .. $cols) {
    foreach my $y (0 .. $rows) {
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
