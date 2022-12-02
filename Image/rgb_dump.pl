#!/usr/bin/perl

# Dump the first n pixels from a given image.

use 5.020;
use warnings;

use Imager;
use experimental qw(signatures);

@ARGV || do {
    say STDERR "usage: $0 [input.png] [n]";
    exit(2);
};

my $in_file = $ARGV[0];
my $n       = $ARGV[1] // 10;

my $img = 'Imager'->new(file => $in_file)
  or die "Can't read image: $in_file";

my $width  = $img->getwidth;
my $height = $img->getheight;

OUTER: foreach my $y (0 .. $height - 1) {
    foreach my $x (0 .. $width - 1) {
        --$n >= 0 or last OUTER;
        my $color = $img->getpixel(x => $x, y => $y);
        my ($r, $g, $b) = $color->rgba;
        printf("%08b,%08b,%08b | %2x,%2x,%2x | %3d,%3d,%3d\n", ($r, $g, $b) x 3);
    }
}
