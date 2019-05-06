#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 06 May 2019
# https://github.com/trizen

# Generate a visual representation of the Pascal powers of two triangle.

# OEIS sequence:
#   https://oeis.org/A307433

use 5.010;
use strict;
use warnings;

use Imager qw();
use Math::GMPz;
use experimental qw(signatures);

sub is_power_of_two ($n) {
    (($n) & ($n - 1)) == 0;
}

my $two_power = 10;
my $size      = 1 << $two_power;
my $img       = Imager->new(xsize => $size, ysize => $size);

my $black = Imager::Color->new('#000000');
my $red   = Imager::Color->new('#ff00000');

$img->box(filled => 1, color => $black);

my $ONE = Math::GMPz->new(1);

sub map_value {
    my ($value, $in_min, $in_max, $out_min, $out_max) = @_;
    ((($value - $in_min) * ($out_max - $out_min)) / ($in_max - $in_min)) + $out_min;
}

sub pascal_powers_of_two {
    my ($rows) = @_;

    my @row = ($ONE);

    foreach my $n (1 .. $rows) {

        my $i      = 0;
        my $offset = ($rows - $n) / 2;

        foreach my $elem (@row) {

            my $t = Math::GMPz::Rmpz_sizeinbase($elem, 2);
            my $hue = ($elem == 1) ? 0 : map_value($t, 0, 1 << ($two_power - 1), 1, 360);

            $img->setpixel(
                           x     => $offset + $i++,
                           y     => $n,
                           color => {
                                     hsv => [$hue, 1, ($elem == 1) ? 0 : 1]
                                    }
                          );
        }

        if ($n <= 11) {
            say "@row";
        }

#<<<
        @row = ($ONE, (map {
            my $t = $row[$_] + $row[$_ + 1];
            is_power_of_two($t) ? $t : $ONE;
        } 0 .. $n - 2), $ONE);
#>>>
    }
}

pascal_powers_of_two($size);

$img->write(file => "pascal_powers_of_two_triangle.png");
