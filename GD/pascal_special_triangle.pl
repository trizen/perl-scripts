#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 06 May 2019
# https://github.com/trizen

# Generate a visual representation of a special Pascal triangle, where all entries satisfy a certain condition.
# If the sum of the two numbers above in the triangle does not satisfy the condition, then we put a constant value in its place.

# OEIS sequences:
#   https://oeis.org/A307116
#   https://oeis.org/A307433

use 5.010;
use strict;
use warnings;

use Imager qw();
use ntheory qw(:all);
use Math::AnyNum;
use experimental qw(signatures);

my $VALUE = Math::AnyNum->new(2);    # constant value

my $size = 1000;
my $img  = Imager->new(xsize => $size, ysize => $size);

my $black = Imager::Color->new('#000000');
my $red   = Imager::Color->new('#ff00000');

$img->box(filled => 1, color => $black);

sub isok ($n) {                      # condition
    kronecker($n - 1, $n) == 1;
}

sub map_value ($value, $in_min, $in_max, $out_min, $out_max) {
    ((($value - $in_min) * ($out_max - $out_min)) / ($in_max - $in_min)) + $out_min;
}

sub special_pascal_triangle ($rows) {

    my @rows;
    my @row = ($VALUE);

    foreach my $n (1 .. $rows) {

        push @rows, [@row];

        if ($n <= 10) {
            say join(' ', map { $_->round } @row);
        }

#<<<
        @row = ($VALUE, (map {
            my $t = $row[$_] + $row[$_ + 1];
            isok($t) ? $t : $VALUE;
        } 0 .. $n - 2), $VALUE);
#>>>
    }

    foreach my $row (@rows) {
        @$row = map { log($_) } @$row;
    }

    my $min_value = vecmin(map { @$_ } @rows);
    my $max_value = vecmax(map { @$_ } @rows);

    say "Min: $min_value";
    say "Max: $max_value";

    foreach my $n (1 .. @rows) {

        my $i      = 0;
        my $offset = ($rows - $n) / 2;

        my $row = $rows[$n - 1];

        foreach my $elem (@$row) {

            my $hue = map_value($elem, $min_value, $max_value, 1, 360);

            $img->setpixel(
                           x     => $offset + $i++,
                           y     => $n,
                           color => {
                                     hsv => [$hue, 1, ($elem == $min_value) ? 0 : 1]
                                    }
                          );
        }
    }
}

special_pascal_triangle($size);

$img->write(file => "special_pascal_triangle.png");
