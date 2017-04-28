#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 20 July 2015
# Website: https://github.com/trizen

# An image generator based on the following formula: n!/(n-1)!, n!/(n-2)!, ... n!/(n-n)!

# Simplified as:
#  n!/(n-1)! = n
#  n!/(n-2)! = n * (n-1)
#  n!/(n-3)! = n * (n-1) * (n-2)

use 5.010;
use strict;
use warnings;
use GD::Simple;

use Math::AnyNum;
use File::Spec::Functions qw(catfile);

my $beg = 3;                      # start point
my $end = 30;                     # end point
my $dir = 'Factorial turtles';    # where to output the images

if (not -d $dir) {
    mkdir($dir)
      or die "Can't mkdir `$dir': $!";
}

foreach my $n ($beg .. $end) {

    {
        local $| = 1;
        printf("[%3d of %3d]\r", $n, $end);
    }

    my $img = 'GD::Simple'->new(5000, 5000);
    $img->moveTo(2500, 2500);
    $img->fgcolor('red');

    my @values;
    my $p = Math::AnyNum->new(1);
    foreach my $j (0 .. $n - 1) {
        $p *= $n - $j;
        push @values, $p;
    }

    for my $i (1 .. 100) {
        foreach my $value (@values) {
            $img->line($i);
            $img->turn($value);
        }
    }

    my $image_name = catfile($dir, sprintf('%03d.png', $n));

    open my $fh, '>:raw', $image_name or die $!;
    print {$fh} $img->png;
    close $fh;
}
