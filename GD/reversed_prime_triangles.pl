#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 26 July 2015
# Website: https://github.com/trizen

# Generate a reversed set of number triangles
# with the prime numbers represented by blue pixels.

use 5.010;
use strict;
use warnings;

use Imager qw();
use ntheory qw(is_prime);

sub triangle {
    my ($rows, $type) = @_;

    my @triangle = ([1]);

    my $n = 1;
    foreach my $i (1 .. $rows) {

        if ($type == 1) {
            foreach my $j (0 .. $#triangle) {
                push @{$triangle[$j]}, ++$n;
                unshift @{$triangle[$j]}, ++$n;
            }
        }
        elsif ($type == 2) {
            foreach my $j (reverse 0 .. $#triangle) {
                push @{$triangle[$j]}, ++$n;
                unshift @{$triangle[$j]}, ++$n;
            }
        }
        elsif ($type == 3) {
            foreach my $j (0 .. $#triangle) {
                unshift @{$triangle[$j]}, ++$n;
            }
            foreach my $j (reverse 0 .. $#triangle) {
                push @{$triangle[$j]}, ++$n;
            }
        }
        elsif ($type == 4) {
            foreach my $j (reverse 0 .. $#triangle) {
                unshift @{$triangle[$j]}, ++$n;
            }
            foreach my $j (0 .. $#triangle) {
                push @{$triangle[$j]}, ++$n;
            }
        }
        else {
            die "Invalid type: $type";
        }

        unshift @triangle, [++$n];
    }

    return \@triangle;
}

sub triangle2img {
    my ($triangle) = @_;

    my $rows = $#{$triangle} + 1;

    my $blue  = Imager::Color->new('#0000FF');
    my $white = Imager::Color->new('#FFFFFF');

    my $img = Imager->new(xsize => $rows * 2, ysize => $rows);
    $img->box(filled => 1, color => $white);

    foreach my $i (0 .. $rows - 1) {
        my $row = $triangle->[$i];

        foreach my $j (0 .. $#{$row}) {
            my $num = $row->[$j];
            if (is_prime($num)) {
                $img->setpixel(x => $rows - $i + $j, y => $i, color => $blue);
            }
            else {
                $img->setpixel(x => $rows - $i + $j, y => $i, color => $white);
            }
        }
    }

    return $img;
}

my $max  = 4;
my $rows = 1000;

foreach my $i (1 .. $max) {
    say "** Generating triangle $i of $max...";

    my $triangle = triangle($rows, $i);
    my $img = triangle2img($triangle);

    $img->write(file => "reversed_triangle_$i.png");
}
