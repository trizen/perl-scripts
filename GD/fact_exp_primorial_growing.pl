#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 19 August 2015
# Website: https://github.com/trizen

# Plot the growing of exponentiation, factorial and primorial.

# blue is n!
# green is n^n
# red is n-primorial

# The plot is logarithmic in base e.

use 5.010;
use strict;
use warnings;

use Imager qw();
use ntheory qw(nth_prime);

my $xsize = 250;
my $ysize = 600;

my $img = Imager->new(xsize => $xsize, ysize => $ysize);

my $white = Imager::Color->new('#ffffff');
my $red   = Imager::Color->new('#ff0000');
my $blue  = Imager::Color->new('#0000ff');
my $green = Imager::Color->new('#00ff00');

$img->box(filled => 1, color => $white);

my $x = 0;

{
    use Math::AnyNum qw(:overload);

    my $f = 1;
    my $p = 1;

    for (my $i = 1 ; $i <= 100 ; ++$i) {

        $f *= $i + 1;
        $p *= nth_prime($i);

        $img->setpixel(x => $x, y => (abs(log($p) - $ysize))->as_int,     color => $red);
        $img->setpixel(x => $x, y => (abs(log($f) - $ysize))->as_int,     color => $blue);
        $img->setpixel(x => $x, y => (abs(log($i**$i) - $ysize))->as_int, color => $green);

        $x++;
    }
}

$img->write(file => 'grow.png');
