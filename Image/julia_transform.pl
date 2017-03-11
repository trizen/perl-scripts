#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 11 March 2017
# https://github.com/trizen

# Julia transform of an image.

# See also:
#   https://en.wikipedia.org/wiki/Julia_set

use 5.010;
use strict;
use warnings;

use Imager;
use List::Util qw(max);

my $file = shift(@ARGV) // die "usage: $0 [image]";

sub map_val {
    my ($value, $in_min, $in_max, $out_min, $out_max) = @_;

#<<<
    ($value - $in_min)
        * ($out_max - $out_min)
        / ($in_max - $in_min)
    + $out_min;
#>>>
}

my $img = Imager->new(file => $file)
  or die Imager->errstr();

my $width  = $img->getwidth;
my $height = $img->getheight;

my ($min_x, $min_y) = (0, 0);
my ($max_x, $max_y) = (0, 0);

sub transform {
    my ($x, $y) = @_;

    use Math::Complex;

#<<<
    my $z = Math::Complex->make(
        (2 * $x - $width ) / $width,
        (2 * $y - $height) / $height,
    );
#>>>

    my $t = $z;
    my $i = 5;
    my $c = log(2);

    while ($t->abs < 2 and --$i >= 0) {
        $t = $t * $t + $c;
    }

    my $real = ref($t) eq 'Math::Complex' ? $t->Re : $t;
    my $imag = ref($t) eq 'Math::Complex' ? $t->Im : 0;

    if ($real < $min_x) {
        $min_x = $real;
    }

    if ($imag < $min_y) {
        $min_y = $imag;
    }

    if ($real > $max_x) {
        $max_x = $real;
    }

    if ($imag > $max_y) {
        $max_y = $imag;
    }

#<<<
    (
        map_val($real, -4 + $c, 4 + $c, 0, $width  - 1),
        map_val($imag, -4,      4,      0, $height - 1),
    );
#>>>
}

my @matrix;
foreach my $y (0 .. $height - 1) {
    foreach my $x (0 .. $width - 1) {
        my ($new_x, $new_y) = transform($x, $y);
        $matrix[$new_y][$new_x] = $img->getpixel(x => $x, y => $y);
    }
}

say "X: [$min_x, $max_x]";
say "Y: [$min_y, $max_y]";

my $out_img = Imager->new(xsize => max(map { ref($_) eq 'ARRAY' ? scalar(@{$_}) : 0 } @matrix),
                          ysize => scalar(@matrix),);

foreach my $y (0 .. $#matrix) {
    my $row = $matrix[$y];
    foreach my $x (0 .. $#{$row}) {
        $out_img->setpixel(x => $x, y => $y, color => $row->[$x]);
    }
}

$out_img->write(file => 'julia_transform.png');
